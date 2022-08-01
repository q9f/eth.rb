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
    #   Dec(15132).to_hex
    #     => "3b1c"
    # @example Pass in a String that represents a base 10 integer
    #   and convert to binary
    #   
    #   Dec['15132'].to_bin
    #     => ";\x1C"
    #   
    class Dec < Num
      # Instantiates a Dec and converts to hex and binary
      #
      # @param input [String, Integer] Base 10 String or Integer
      # @example Instantiate a Dec object
      #   Dec.new(3735928559)
      #     => #<Eth::Types::Dec:0x00007f8dcb102330
      #       @input="0xdeadbeef",
      #       @hex="deadbeef",
      #       @bin="\xDE\xAD\xBE\xEF",
      #       @dec=3735928559>
      def initialize(dec)
        super(dec) do
          to_dec
          to_hex
          to_bin
        end
      end

      def to_dec
        @dec ||= input.to_i
      end

      def to_hex
        @hex ||= dec.to_s(16)
        format_hex!
      end

      def to_bin
        @bin ||= _hex_to_bin
      end

      def valid?
        input.is_a?(Fixnum) || input.to_i.to_s == input
      end
    end
  end
end
