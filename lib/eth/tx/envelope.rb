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

    # The EIP-2930 transaction type is 1.
    TYPE_2930 = 0x01

    # The EIP-1559 transaction type is 2.
    TYPE_1559 = 0x02

    # The EIP-2718 transaction envelope.
    class Envelope

      # The EIP-2718 transaction type.
      attr_reader :type

      # The EIP-2718 transaction payload.
      attr_reader :payload

      # Creates an EIP-2718 transaction envelope containing
      # a transaction payload and a transaction type.
      #
      # @param payload [Eip2930Payload or Eip1559Payload] the EIP-2718 transaction type.
      # @param type [Integer] the EIP-2718 transaction type.
      def initialize(payload, type = TYPE_1559)
        unless payload.instance_of? Eth::Tx::Eip2930Payload or payload.instance_of? Eth::Tx::Eip1559Payload
          raise ArgumentError, "Unknown transaction payload #{payload}!"
        end
        unless type == Eth::Tx::TYPE_2930 or type == Eth::Tx::TYPE_1559
          raise ArgumentError, "Unknown transaction type #{type}!"
        end
        @payload = payload
        @type = type
      end
    end
  end
end
