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

# -*- encoding : ascii-8bit -*-

# Provides the {Eth} module.
module Eth
  
  # Provides a namespace for the numeric types.
  module Types

    # Subclass of {Num} that represents a binary string / bytestring.
    #
    # @see {Num}
    #
    # @example Pass in a bytestring and convert to hex.
    #   Bin(Keccak256.digest('eh')).to_hex
    #     =>  
    class Bin < Num

      # Instantiates a Bin / bytestring
      #   then uses conversion methods to set the {Hex} and
      #   {Dec} values.
      #
      # @example Bin(keccak_string).hex
      # @example Bin(keccak_string).to_hex
      #
      # @example Bin(keccak_string).dec
      # @example Bin(keccak_string).to_i
      #
      # @example Bin(keccak_string).bin
      # @example Bin(keccak_string).to_bin
      def initialize(input)
        @bin = input.b
        @hex = Hex(bin.unpack1("H*"))
        @dec = Dec(hex.input.to_i(16))
      end
    end
  end
end
