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
    #     => "de1b7b28eff2472387272a3db303cca4f84296a0c1440927d67abd6770a2097e" 
    class Bin < Num

      # Instantiates a Bin / bytestring
      #
      # @example Instantiate a Bin object
      #   Bin('0xdeadbeef')
      #     => #<Eth::Types::Bin:0x00007f8dcb102330
      #       @input="0xdeadbeef",
      #       @hex="deadbeef",
      #       @bin="\xDE\xAD\xBE\xEF",
      #       @dec=3735928559>
      def initialize(bin)
        super(bin) do
          to_bin
          to_hex
          to_dec
        end
      end

      def to_bin
        @bin ||= input.b
      end

      def to_hex
        @hex ||= _bin_to_hex
        format_hex!
      end

      def to_dec
        @dec ||= hex.to_i(16)
      end

      def valid?
        bytes?
      end
    end
  end
end
