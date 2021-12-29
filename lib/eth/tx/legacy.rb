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

      # Create a legacy transaction object that can be prepared for
      # signature and broadcast. Should not be used unless there is
      # no EIP-1559 support.
      #
      # @param nonce [Integer] the transaction signer nonce.
      # @param price [Integer] the transaction gas price in Wei.
      # @param limit [Integer] the transaction gas limit.
      # @param to [Eth::Address] the transaction destination.
      # @param value [Integer] the transaction amount in Wei.
      # @param data [String] the transaction hex-string payload.
      def initialize(nonce, price, limit, to = "", value = 0, data = "")
        unless nonce >= 0
          raise ArgumentError, "Invalid signer nonce #{nonce}!"
        end
        unless price >= 0
          raise ArgumentError, "Invalid gas price #{price}!"
        end
        unless limit >= DEFAULT_LIMIT and limit <= BLOCK_LIMIT
          raise ArgumentError, "Invalid gas limit #{limit}!"
        end
        if to.is_a? String and !to.empty?
          to = Address.new(to).to_s
          to = Util.remove_hex_prefix to
        end
        unless value >= 0
          raise ArgumentError, "Invalid transaction value #{value}!"
        end
        @signer_nonce = nonce.to_i
        @gas_price = price.to_i
        @gas_limit = limit.to_i
        @destination = to
        @amount = value.to_i
        @payload = data
      end

      konstructor

      def decode(hex)
        bin = Util.hex_to_bin hex
        tx = RLP.decode(bin)
        if tx.size < 9
          raise "WOOT"
        end
        nonce = Util.deserialize_big_endian_to_int tx[0]
        price = Util.deserialize_big_endian_to_int tx[1]
        limit = Util.deserialize_big_endian_to_int tx[2]
        to = Util.bin_to_hex tx[3]
        value = Util.deserialize_big_endian_to_int tx[4]
        data = tx[5]
        v = Util.bin_to_hex tx[6]
        r = Util.bin_to_hex tx[7]
        s = Util.bin_to_hex tx[8]

        @signer_nonce = nonce.to_i
        @gas_price = price.to_i
        @gas_limit = limit.to_i
        @destination = to
        @amount = value.to_i
        @payload = data
        set_signature(v, r, s)
      end

      # Sign the transaction with a given key.
      #
      # @param key [Eth::Key] the key-pair to use for signing.
      # @param chain_id [Integer] the chain to sign on.
      # @raise [StandardError] if the transaction is already signed.
      def sign(key, chain_id = Chain::ETHEREUM)
        if is_signed?
          raise StandardError, "Transaction is already signed!"
        end

        # sign a keccak hash of the unsigned, encoded transaction
        signature = key.sign(unsigned_hash, chain_id)
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
        tx_data = unsigned
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

      alias raw hex

      # Gets the transaction hash.
      #
      # @return [String] the transaction hash.
      def hash
        Util.bin_to_hex Util.keccak256 encoded
      end

      private

      def unsigned
        tx_data = []
        tx_data.push Util.serialize_int_to_big_endian @signer_nonce
        tx_data.push Util.serialize_int_to_big_endian @gas_price
        tx_data.push Util.serialize_int_to_big_endian @gas_limit
        tx_data.push Util.hex_to_bin @destination
        tx_data.push Util.serialize_int_to_big_endian @amount
        tx_data.push @payload # @TODO
      end

      def unsigned_encoded
        RLP.encode unsigned
      end

      def unsigned_hex
        Util.bin_to_hex unsigned_encoded
      end

      def unsigned_hash
        Util.keccak256 unsigned_encoded
      end

      protected

      def is_signed?
        !@signature_v.nil? and signature_v != 0 and
        !signature_r.nil? and signature_v != 0 and
        !signature_s.nil? and signature_v != 0
      end

      def set_signature(v, r, s)
        @signature_v = v
        @signature_r = r
        @signature_s = s
      end
    end
  end
end
