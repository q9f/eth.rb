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

# Provides the {Eth} module.
module Eth

  # Provides the `Tx` module supporting various transaction types.
  module Tx

    # Provides legacy support for transactions on blockchains that do not
    # implement EIP-1559, EIP-2718, or EIP-2930.
    class Legacy

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

      # The signature `v` byte.
      attr_reader :signature_v

      # The signature `r` value.
      attr_reader :signature_r

      # The signature `s` value.
      attr_reader :signature_s

      # The EIP-155 chain ID field.
      # Ref: https://eips.ethereum.org/EIPS/eip-155
      attr_reader :chain_id

      # The sender address.
      attr_reader :sender

      # The transaction type.
      attr_reader :type

      # Create a legacy transaction object that can be prepared for
      # signature and broadcast. Should not be used unless there is
      # no EIP-1559 support.
      #
      # @param params [Hash] all necessary transaction fields.
      # @option params [Integer] :nonce the signer nonce.
      # @option params [Integer] :gas_price the gas price.
      # @option params [Integer] :gas_limit the gas limit.
      # @option params [Eth::Address] :from the sender address.
      # @option params [Eth::Address] :to the reciever address.
      # @option params [Integer] :value the transaction value.
      # @option params [String] :data the transaction data payload.
      # @param chain_id [Integer] the EIP-155 Chain ID.
      # @raise [ParameterError] if gas limit is too low.
      def initialize(params, chain_id = Chain::ETHEREUM)
        fields = { v: chain_id, r: 0, s: 0 }.merge params

        # populate optional fields with serializable empty values
        fields[:value] = Tx.sanitize_amount fields[:value]
        fields[:from] = Tx.sanitize_address fields[:from]
        fields[:to] = Tx.sanitize_address fields[:to]
        fields[:data] = Tx.sanitize_data fields[:data]

        # ensure sane values for all mandatory fields
        fields = Tx.validate_params fields
        fields = Tx.validate_legacy_params fields

        # ensure gas limit is not too low
        minimum_cost = Tx.estimate_intrinsic_gas fields[:data]
        raise ParameterError, "Transaction gas limit is too low, try #{minimum_cost}!" if fields[:gas_limit].to_i < minimum_cost

        # populate class attributes
        @signer_nonce = fields[:nonce].to_i
        @gas_price = fields[:gas_price].to_i
        @gas_limit = fields[:gas_limit].to_i
        @sender = fields[:from].to_s
        @destination = fields[:to].to_s
        @amount = fields[:value].to_i
        @payload = fields[:data]

        # the signature v is set to the chain id for unsigned transactions
        @signature_v = fields[:v]
        @chain_id = chain_id

        # the signature fields are empty for unsigned transactions.
        @signature_r = fields[:r]
        @signature_s = fields[:s]

        # last but not least, set the type.
        @type = TYPE_LEGACY
      end

      # overloads the constructor for decoding raw transactions and creating unsigned copies
      konstructor :decode, :unsigned_copy

      # Decodes a raw transaction hex into an {Eth::Tx::Legacy}
      # transaction object.
      #
      # @param hex [String] the raw transaction hex-string.
      # @return [Eth::Tx::Legacy] transaction object.
      # @raise [ParameterError] if transaction misses fields.
      def decode(hex)
        bin = Util.hex_to_bin hex
        tx = Rlp.decode bin

        # decoded transactions always have 9 fields, even if they are empty or zero
        raise ParameterError, "Transaction missing fields!" if tx.size < 9

        # populate the 9 fields
        nonce = Util.deserialize_big_endian_to_int tx[0]
        gas_price = Util.deserialize_big_endian_to_int tx[1]
        gas_limit = Util.deserialize_big_endian_to_int tx[2]
        to = Util.bin_to_hex tx[3]
        value = Util.deserialize_big_endian_to_int tx[4]
        data = tx[5]
        v = Util.bin_to_hex tx[6]
        r = Util.bin_to_hex tx[7]
        s = Util.bin_to_hex tx[8]

        # try to recover the chain id from v
        chain_id = Chain.to_chain_id Util.deserialize_big_endian_to_int tx[6]

        # populate class attributes
        @signer_nonce = nonce.to_i
        @gas_price = gas_price.to_i
        @gas_limit = gas_limit.to_i
        @destination = to.to_s
        @amount = value.to_i
        @payload = data
        @chain_id = chain_id

        # allows us to force-setting a signature if the transaction is signed already
        _set_signature(v, r, s)

        unless chain_id.nil?

          # recover sender address
          public_key = Signature.recover(unsigned_hash, "#{r}#{s}#{v}", chain_id)
          address = Util.public_key_to_address(public_key).to_s
          @sender = Tx.sanitize_address address
        else

          # keep the 'from' field blank
          @sender = Tx.sanitize_address nil
        end

        # last but not least, set the type.
        @type = TYPE_LEGACY
      end

      # Creates an unsigned copy of a transaction.
      #
      # @param tx [Eth::Tx::Legacy] an legacy transaction object.
      # @return [Eth::Tx::Legacy] an unsigned transaction object.
      # @raise [TransactionTypeError] if transaction type does not match.
      def unsigned_copy(tx)

        # not checking transaction validity unless it's of a different class
        raise TransactionTypeError, "Cannot copy transaction of different type!" unless tx.instance_of? Tx::Legacy

        # populate class attributes
        @signer_nonce = tx.signer_nonce
        @gas_price = tx.gas_price
        @gas_limit = tx.gas_limit
        @destination = tx.destination
        @amount = tx.amount
        @payload = tx.payload
        @chain_id = tx.chain_id

        # force-set signature to unsigned
        _set_signature(tx.chain_id, 0, 0)

        # keep the 'from' field blank
        @sender = Tx.sanitize_address nil

        # last but not least, set the type.
        @type = TYPE_LEGACY
      end

      # Sign the transaction with a given key.
      #
      # @param key [Eth::Key] the key-pair to use for signing.
      # @return [String] a transaction hash.
      # @raise [Signature::SignatureError] if transaction is already signed.
      # @raise [Signature::SignatureError] if sender address does not match signing key.
      def sign(key)
        if Tx.is_signed? self
          raise Signature::SignatureError, "Transaction is already signed!"
        end

        # ensure the sender address matches the given key
        unless @sender.nil? or sender.empty?
          signer_address = Tx.sanitize_address key.address.to_s
          from_address = Tx.sanitize_address @sender
          raise Signature::SignatureError, "Signer does not match sender" unless signer_address == from_address
        end

        # sign a keccak hash of the unsigned, encoded transaction
        signature = key.sign(unsigned_hash, @chain_id)
        r, s, v = Signature.dissect signature
        @signature_v = v
        @signature_r = r
        @signature_s = s
        return hash
      end

      # Encodes a raw transaction object.
      #
      # @return [String] a raw, RLP-encoded legacy transaction.
      # @raise [Signature::SignatureError] if the transaction is not yet signed.
      def encoded
        unless Tx.is_signed? self
          raise Signature::SignatureError, "Transaction is not signed!"
        end
        tx_data = []
        tx_data.push Util.serialize_int_to_big_endian @signer_nonce
        tx_data.push Util.serialize_int_to_big_endian @gas_price
        tx_data.push Util.serialize_int_to_big_endian @gas_limit
        tx_data.push Util.hex_to_bin @destination
        tx_data.push Util.serialize_int_to_big_endian @amount
        tx_data.push Rlp::Sedes.binary.serialize @payload
        tx_data.push Util.serialize_int_to_big_endian @signature_v
        tx_data.push Util.serialize_int_to_big_endian @signature_r
        tx_data.push Util.serialize_int_to_big_endian @signature_s
        Rlp.encode tx_data
      end

      # Gets the encoded, raw transaction hex.
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

      # Encodes the unsigned transaction object, required for signing.
      #
      # @return [String] an RLP-encoded, unsigned transaction.
      def unsigned_encoded
        tx_data = []
        tx_data.push Util.serialize_int_to_big_endian @signer_nonce
        tx_data.push Util.serialize_int_to_big_endian @gas_price
        tx_data.push Util.serialize_int_to_big_endian @gas_limit
        tx_data.push Util.hex_to_bin @destination
        tx_data.push Util.serialize_int_to_big_endian @amount
        tx_data.push Rlp::Sedes.binary.serialize @payload
        tx_data.push Util.serialize_int_to_big_endian @chain_id
        tx_data.push Util.serialize_int_to_big_endian 0
        tx_data.push Util.serialize_int_to_big_endian 0
        Rlp.encode tx_data
      end

      # Gets the sign-hash required to sign a raw transaction.
      #
      # @return [String] a Keccak-256 hash of an unsigned transaction.
      def unsigned_hash
        Util.keccak256 unsigned_encoded
      end

      private

      # Force-sets an existing signature of a decoded transaction.
      def _set_signature(v, r, s)
        @signature_v = v
        @signature_r = r
        @signature_s = s
      end
    end
  end
end
