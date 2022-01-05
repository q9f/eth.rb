# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Provides the `Eth` module.
module Eth

  # Provides the `Tx` module supporting various transaction types.
  module Tx

    # Provides legacy support for transactions on blockchains that do not
    # implement EIP-1559 but still want to utilize EIP-2718 envelopes.
    class Eip2930

      # The EIP-155 Chain ID.
      attr_reader :chain_id

      # The transaction nonce provided by the signer.
      attr_reader :signer_nonce

      # The gas price for the transaction in Wei.
      attr_reader :gas_price

      # The gas limit for the transaction.
      attr_reader :gas_limit

      # The recipient address.
      attr_reader :destination

      # The transaction amount in Wei.
      attr_reader :amount

      # The transaction data payload.
      attr_reader :payload

      # An optional EIP-2930 access list.
      attr_reader :access_list

      # The signature's y-parity byte (not v).
      attr_reader :signature_y_parity

      # The signature `r` value.
      attr_reader :signature_r

      # The signature `s` value.
      attr_reader :signature_s

      # Create a legacy type-1 (EIP-2930) transaction payload object that
      # can be prepared for envelope, signature and broadcast. Should not
      # be used unless there is no EIP-1559 support.
      #
      # @param params [Hash] all necessary transaction fields (nonce, gas_price, gas_limit, to, value, data_bin, access_list).
      # @param chain_id [Integer] the EIP-155 Chain ID.
      def initialize(params, chain_id = Chain::ETHEREUM)
        fields = { recovery_id: nil, r: 0, s: 0 }.merge params

        # populate optional fields with serializable empty values
        fields[:value] = Tx.sanitize_amount fields[:value]
        fields[:to] = Tx.sanitize_address fields[:to]
        fields[:data_bin] = Tx.sanitize_data fields[:data_bin]

        # ensure sane values for all mandatory fields
        fields = Tx.validate_legacy_params fields

        # populate class attributes
        @signer_nonce = fields[:nonce].to_i
        @gas_price = fields[:gas_price].to_i
        @gas_limit = fields[:gas_limit].to_i
        @destination = fields[:to].to_s
        @amount = fields[:value].to_i
        @payload = fields[:data_bin]
        @access_list = fields[:access_list]

        # the signature v is set to the chain id for unsigned transactions
        @signature_y_parity = fields[:recovery_id]
        @chain_id = chain_id

        # the signature fields are empty for unsigned transactions.
        @signature_r = fields[:r]
        @signature_s = fields[:s]
      end

      # overloads the constructor for decoding raw transactions and creating unsigned copies
      konstructor :decode, :unsigned_copy

      # Decodes a raw transaction hex into an Eth::Tx::Eip2930
      # transaction object.
      #
      # @param hex [String] the raw transaction hex-string.
      # @return [Eth::Tx::Eip2930] transaction payload.
      def decode(hex)
        type = hex[0, 2]
        raise StandardError, "Invalid transaction type #{type}!" if type.to_i(16) != TYPE_2930

        bin = Util.hex_to_bin hex[2..]
        tx = RLP.decode(bin)

        # decoded transactions always have 8 + 3 fields, even if they are empty or zero
        raise StandardError, "Transaction missing fields!" if tx.size < 8

        # populate the 8 payload fields
        chain_id = Util.deserialize_big_endian_to_int tx[0]
        nonce = Util.deserialize_big_endian_to_int tx[1]
        gas_price = Util.deserialize_big_endian_to_int tx[2]
        gas_limit = Util.deserialize_big_endian_to_int tx[3]
        to = Util.bin_to_hex tx[4]
        value = Util.deserialize_big_endian_to_int tx[5]
        data_bin = tx[6]
        access_list = tx[7]

        # populate class attributes
        @chain_id = chain_id
        @signer_nonce = nonce.to_i
        @gas_price = gas_price.to_i
        @gas_limit = gas_limit.to_i
        @destination = to.to_s
        @amount = value.to_i
        @payload = data_bin
        @access_list = access_list

        # populate the 3 signature fields
        if tx.size == 8
          _set_signature(nil, 0, 0)
        elsif tx.size == 11
          recovery_id = Util.bin_to_hex(tx[8]).to_i(16)
          r = Util.bin_to_hex tx[9]
          s = Util.bin_to_hex tx[10]

          # allows us to force-setting a signature if the transaction is signed already
          _set_signature(recovery_id, r, s)
        else
          raise_error StandardError "Cannot decode EIP-2930 payload!"
        end
      end

      # Creates an unsigned copy of a transaction payload.
      #
      # @param tx [Eth::Tx::Eip2930] an EIP-2930 transaction payload.
      # @return [Eth::Tx::Eip2930] an unsigned EIP-2930 transaction payload.
      def unsigned_copy(tx)

        # not checking transaction validity unless it's of a different class
        raise ArgumentError "Cannot copy transaction of different payload type!" unless tx.instance_of? Tx::Eip2930

        # populate class attributes
        @signer_nonce = tx.signer_nonce
        @gas_price = tx.gas_price
        @gas_limit = tx.gas_limit
        @destination = tx.destination
        @amount = tx.amount
        @payload = tx.payload
        @access_list = tx.access_list
        @chain_id = tx.chain_id

        # force-set signature to unsigned
        _set_signature(nil, 0, 0)
      end

      # Sign the transaction with a given key.
      #
      # @param key [Eth::Key] the key-pair to use for signing.
      # @raise [StandardError] if the transaction is already signed.
      def sign(key)
        if Tx.is_signed? self
          raise StandardError, "Transaction is already signed!"
        end

        # sign a keccak hash of the unsigned, encoded transaction
        signature = key.sign(unsigned_hash, @chain_id)
        r, s, v = Signature.dissect signature
        recovery_id = Chain.to_recovery_id v.to_i(16), @chain_id
        @signature_y_parity = recovery_id
        @signature_r = r
        @signature_s = s
      end

      # Encodes a raw transaction object, wraps it in an EIP-2718 envelope
      # with an EIP-2930 type prefix.
      #
      # @return [String] a raw, RLP-encoded EIP-2930 type transaction object.
      # @raise [StandardError] if the transaction is not yet signed.
      def encoded
        unless Tx.is_signed? self
          raise StandardError, "Transaction is not signed!"
        end
        tx_data = []
        tx_data.push Util.serialize_int_to_big_endian @chain_id
        tx_data.push Util.serialize_int_to_big_endian @signer_nonce
        tx_data.push Util.serialize_int_to_big_endian @gas_price
        tx_data.push Util.serialize_int_to_big_endian @gas_limit
        tx_data.push Util.hex_to_bin @destination
        tx_data.push Util.serialize_int_to_big_endian @amount
        tx_data.push @payload
        tx_data.push @access_list
        tx_data.push Util.serialize_int_to_big_endian @signature_y_parity
        tx_data.push Util.hex_to_bin @signature_r
        tx_data.push Util.hex_to_bin @signature_s
        tx_encoded = RLP.encode tx_data

        # create an EIP-2718 envelope with EIP-2930 type payload
        tx_type = Util.serialize_int_to_big_endian TYPE_2930
        return "#{tx_type}#{tx_encoded}"
      end

      # Gets the encoded, enveloped, raw transaction hex.
      #
      # @return [String] the raw transaction hex.
      def hex
        Util.bin_to_hex encoded
      end

      # Gets the transaction hash.
      #
      # @return [String] the transaction hash.
      def hash
        Util.bin_to_hex Util.keccak256 encoded
      end

      # Encodes the unsigned transaction payload in an EIP-2930 envelope,
      # required for signing.
      #
      # @return [String] an RLP-encoded, unsigned, enveloped EIP-2930 transaction.
      def unsigned_encoded
        tx_data = []
        tx_data.push Util.serialize_int_to_big_endian @chain_id
        tx_data.push Util.serialize_int_to_big_endian @signer_nonce
        tx_data.push Util.serialize_int_to_big_endian @gas_price
        tx_data.push Util.serialize_int_to_big_endian @gas_limit
        tx_data.push Util.hex_to_bin @destination
        tx_data.push Util.serialize_int_to_big_endian @amount
        tx_data.push @payload
        tx_data.push @access_list
        tx_encoded = RLP.encode tx_data

        # create an EIP-2718 envelope with EIP-2930 type payload (unsigned)
        tx_type = Util.serialize_int_to_big_endian TYPE_2930
        return "#{tx_type}#{tx_encoded}"
      end

      # Gets the sign-hash required to sign a raw transaction.
      #
      # @return [String] a Keccak-256 hash of an unsigned transaction.
      def unsigned_hash
        Util.keccak256 unsigned_encoded
      end

      private

      def _set_signature(recovery_id, r, s)
        @signature_y_parity = recovery_id
        @signature_r = r
        @signature_s = s
      end
    end
  end
end
