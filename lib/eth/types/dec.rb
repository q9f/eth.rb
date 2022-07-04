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
  
  module Types
    # Subclass of {Num} that represents a base 10 integer
    #
    # @see {Num}
    #
    # @example Pass in an integer and convert to hex
    #   Dec[15132].to_hex
    #     =>  
    # @example Pass in a String that represents a base 10 integer
    #   and convert to binary
    #   
    #   Dec['15132'].to_bin
    #   
    class Dec < Num
#      extend Eth::Types

      # Instantiates a Dec and converts to hex and binary
      #
      # @param input [String, Integer] Base 10 String or Integer
      def initialize(input)
        binding.pry
        @dec = input.to_i

        @hex = Hex(dec.to_s(16))
        @bin = Bin(hex.scan(/../).map(&:hex).pack("C*"))
      end

      def zpad(expected_length)
        dec.to_s.rjust(expected_length, '0')
      end
    end
  end
end
