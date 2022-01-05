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
      attr_reader :chain_id

      # Create a legacy transaction object that can be prepared for
      # signature and broadcast. Should not be used unless there is
      # no EIP-1559 support.
      #
      # @param params [Hash] all necessary transaction fields (nonce, gas_price, gas_limit, to, value, data_bin).
      # @param chain_id [Integer] the EIP-155 chain id.
      def initialize(params, chain_id = Chain::ETHEREUM)
        fields = { v: chain_id, r: 0, s: 0 }.merge params

        # populate optional fields with serializable empty values
        fields[:to] = "" if fields[:to].nil?
        fields[:value] = 0 if fields[:value].nil?
        fields[:data_bin] = "" if fields[:data_bin].nil?

        # ensure payload to be binary if it's hex, otherwise we'll treat it raw
        fields[:data_bin] = Util.hex_to_bin fields[:data_bin] if Util.is_hex? fields[:data_bin]

        # ensure sane values for all mandatory fields
        unless fields[:nonce] >= 0
          raise ArgumentError, "Invalid signer nonce #{fields[:nonce]}!"
        end
        unless fields[:gas_price] >= 0
          raise ArgumentError, "Invalid gas price #{fields[:gas_price]}!"
        end
        unless fields[:gas_limit] >= DEFAULT_LIMIT and fields[:gas_limit] <= BLOCK_LIMIT
          raise ArgumentError, "Invalid gas limit #{fields[:gas_limit]}!"
        end
        if fields[:to].is_a? String and !fields[:to].empty?
          fields[:to] = Address.new(fields[:to]).to_s
          fields[:to] = Util.remove_hex_prefix fields[:to]
        end
        unless fields[:value] >= 0
          raise ArgumentError, "Invalid transaction value #{fields[:value]}!"
        end

        # populate class attributes
        @signer_nonce = fields[:nonce].to_i
        @gas_price = fields[:gas_price].to_i
        @gas_limit = fields[:gas_limit].to_i
        @destination = fields[:to].to_s
        @amount = fields[:value].to_i
        @payload = fields[:data_bin]

        # the signature v is set to the chain id for unsigned transactions
        @signature_v = fields[:v]
        @chain_id = chain_id

        # the signature fields are empty for unsigned transactions.
        @signature_r = fields[:r]
        @signature_s = fields[:s]
      end

      # overloads the constructor for decoding raw transactions and creating unsigned copies
      konstructor :decode, :unsigned_copy

      # Decodes a raw transaction hex into an Eth::Tx::Legacy
      # transaction object.
      #
      # @param hex [String] the raw transaction hex-string.
      # @return [Eth::Tx::Legacy] transaction object.
      def decode(hex)
        bin = Util.hex_to_bin hex
        tx = RLP.decode(bin)

        # decoded transactions always have 9 fields, even if they are empty or zero
        raise StandardError, "Transaction missing fields!" if tx.size < 9

        # populate the 9 fields
        nonce = Util.deserialize_big_endian_to_int tx[0]
        gas_price = Util.deserialize_big_endian_to_int tx[1]
        gas_limit = Util.deserialize_big_endian_to_int tx[2]
        to = Util.bin_to_hex tx[3]
        value = Util.deserialize_big_endian_to_int tx[4]
        data_bin = tx[5]
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
        @payload = data_bin
        @chain_id = chain_id

        # allows us to force-setting a signature if the transaction is signed already
        _set_signature(v, r, s)
      end

      # Creates an unsigned copy of a transaction.
      #
      # @param tx [Eth::Tx::Legacy] an legacy transaction object.
      # @return [Eth::Tx::Legacy] an unsigned transaction object.
      def unsigned_copy(tx)

        # not checking transaction validity unless it's of a different class
        raise ArgumentError "Cannot copy transaction of different type!" unless tx.instance_of? Eth::Tx::Legacy

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
      end

      # Sign the transaction with a given key.
      #
      # @param key [Eth::Key] the key-pair to use for signing.
      # @raise [StandardError] if the transaction is already signed.
      def sign(key)
        if is_signed?
          raise StandardError, "Transaction is already signed!"
        end

        # sign a keccak hash of the unsigned, encoded transaction
        signature = key.sign(unsigned_hash, @chain_id)
        r, s, v = Signature.dissect signature
        @signature_v = v
        @signature_r = r
        @signature_s = s
      end

      # Encodes a raw transaction object.
      #
      # @return [String] a raw, RLP-encoded legacy transaction.
      # @raise [StandardError] if the transaction is not yet signed.
      def encoded
        unless is_signed?
          raise StandardError, "Transaction is not signed!"
        end
        tx_data = []
        tx_data.push Util.serialize_int_to_big_endian @signer_nonce
        tx_data.push Util.serialize_int_to_big_endian @gas_price
        tx_data.push Util.serialize_int_to_big_endian @gas_limit
        tx_data.push Util.hex_to_bin @destination
        tx_data.push Util.serialize_int_to_big_endian @amount
        tx_data.push @payload
        tx_data.push Util.hex_to_bin @signature_v
        tx_data.push Util.hex_to_bin @signature_r
        tx_data.push Util.hex_to_bin @signature_s
        RLP.encode tx_data
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
        tx_data.push @payload
        tx_data.push Util.serialize_int_to_big_endian @signature_v
        tx_data.push Util.serialize_int_to_big_endian @signature_r
        tx_data.push Util.serialize_int_to_big_endian @signature_s
        RLP.encode tx_data
      end

      # Gets the sign-hash required to sign a raw transaction.
      #
      # @return [String] a Keccak-256 hash of an unsigned transaction.
      def unsigned_hash
        Util.keccak256 unsigned_encoded
      end

      # Allows to check wether a transaction is signed already.
      #
      # @return [Bool] true if transaction is already signed.
      def is_signed?
        !@signature_r.nil? and @signature_r != 0 and
        !@signature_s.nil? and @signature_s != 0
      end

      private

      def _set_signature(v, r, s)
        @signature_v = v
        @signature_r = r
        @signature_s = s
      end
    end
  end
end
