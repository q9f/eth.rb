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

    # Provides support for EIP-1559 transactions utilizing EIP-2718
    # types and envelopes.
    class Eip1559

      # The EIP-155 Chain ID.
      attr_reader :chain_id

      # The transaction nonce provided by the signer.
      attr_reader :signer_nonce

      # The transaction max priority fee per gas in Wei.
      attr_reader :max_priority_fee_per_gas

      # The transaction base fee per gas in Wei.
      attr_reader :max_fee_per_gas

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

      # Create a type-2 (EIP-1559) transaction payload object that
      # can be prepared for envelope, signature and broadcast.
      #
      # @param to [Eth::Address] the transaction destination.
      # @param fee [Integer] the transaction max priority gas fee in Wei.
      # @param price [Integer] the transaction base gas fee in Wei.
      # @param limit [Integer] the transaction gas limit.
      # @param nonce [Integer] the transaction signer nonce.
      # @param value [Integer] the transaction amount in Wei.
      # @param data [String] the transaction hex-string payload.
      # @param access_list [Array] an optional EIP-2930 access list.
      # @param chain_id [Integer] the EIP-155 Chain ID.
      def initialize(fee, price, limit, nonce, to = "", value = 0, data = "", access_list = [], chain_id = Chain::ETHEREUM)
        if to.is_a? String and !to.empty?
          to = Address.new to
        end
        unless fee >= 0
          raise ArgumentError, "Invalid gas priority fee #{fee}!"
        end
        unless price >= 0
          raise ArgumentError, "Invalid gas base price #{price}!"
        end
        unless limit >= DEFAULT_LIMIT and limit <= BLOCK_LIMIT
          raise ArgumentError, "Invalid gas limit #{limit}!"
        end
        unless nonce >= 0
          raise ArgumentError, "Invalid signer nonce #{nonce}!"
        end
        unless value >= 0
          raise ArgumentError, "Invalid transaction value #{value}!"
        end
        @chain_id = chain_id
        @signer_nonce = nonce
        @max_priority_fee_per_gas = fee
        @max_fee_per_gas = price
        @gas_limit = limit
        @destination = to
        @amount = value
        @payload = data
        @access_list = access_list
      end
    end
  end
end
