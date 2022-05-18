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
    # Provides a numeric data type with painless conversions
    #   between bytes, hex, and decimal. {Num}'s constructor
    #   should not be given a value directly. Instead, use
    #   one of its subclasses.
    #
    # @see {https://github.com/q9f/secp256k1.cr/blob/master/src/secp256k1/num.cr}
    #
    # @example Num.new
    #     => 
    #
    # @raise [ArgumentError] raised if input is a String but
    #   isn't hex or bytes, or if input is an Array but not
    #   a list of ascii-8bit numbers
    class Num

      # value in decimal
      attr_reader :dec
      alias to_i dec

      # value as bytestring
      attr_reader :bin
      alias to_bytes bin
      alias to_bin bin

      # value in hexa-decimal
      attr_reader :hex
      alias to_hex hex

      # Instantiates a Num with {@hex} set to {SecureRandom.hex(16)}
      #   then uses conversion methods to set the bytestring and
      #   {Integer}.
      def initialize(input = nil)
        @input = input

        @hex = Hex(SecureRandom.hex(16))
        @bin = Bin(hex)
        @dec = Dec(hex)

        validate!
      end

      def self.inherited(base)
#        base.extend(TypeShortcuts)
      end

      def [](input = nil)
        self.class.new(input)
      end

      def validate_input!
        raise ArgumentError, "Could not convert input to bin, hex, and dec"
      end

      # Memoizes and returns 0x-prefixed hex
      #
      # @see {Eth::Refinements::Conversions::String#to_prefixed_hex}
      def to_prefixed_hex
        @prefixed_hex ||= "0x#{hex}"
      end

      # Memoizes and returns zpadded hex
      #
      # @see {Eth::Refinements::Conversions::String#zpad}
      def to_zpadded_hex(length = 64)
        @zpadded_hex ||= hex.zpad(length)
      end

      # Memoizes and returns zpadded bytes
      #
      # @see {Eth::Refinements::Conversions::String#zpad}
      def to_zpadded_bytes(length = 32)
        @zpadded_bytes ||= bytes.zpad(length)
      end
    end
  end
end
