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
  
  # Provides a numeric data type with painless conversions
  #   between bytes, hex, and decimal
  #
  # @see {https://github.com/q9f/secp256k1.cr/blob/master/src/secp256k1/num.cr}
  # @example Pass in a 0x-prefixed String and convert to bytestring. 
  #   Num.new('0xDEADBeeF').to_bytes
  #   Num['0xDEADBeeF'].to_bytes
  # @example Pass in a serialized Keccak256 String and convert to 0x-hex
  #   Num[Util.keccak256('test')].to_prefixed_hex
  # @example Pass in a serialized Keccak256 String and convert to 0x-hex
  # @raise [ArgumentError] raised if input is a String but
  #   isn't hex or bytes, or if input is an Array but not
  #   a list of ascii-8bit numbers
  class Num
    using Refinements::Conversions

    # raw input
    attr_reader :input

    # value in decimal
    attr_reader :integer

    # value as bytestring
    attr_reader :bytes

    # value in hexa-decimal
    attr_reader :hex

    # Instantiates a Num with an Integer or a String representation of
    # bytes, hex, or decimal.
    #
    # @param [nil, Integer, String] 
    def initialize(input = nil)
      @input = input
      coerce!
    end

    # class << self
    #   alias [] new
    # end

    # Eagerly sets all value types. Uses the conversion methods
    # in {Eth::Refinements::Conversions}
    def coerce!
      case input
      when Integer
        @integer = input
        @hex = integer.to_hex
        @bytes = integer.to_bytes
      when String
        if input.hex?
          @hex = input.to_hex
          @bytes = hex.to_bytes
          @integer = bytes.to_i
        elsif input.bytes?
          @bytes = input.to_bytes
          @hex = bytes.to_hex
          @integer = bytes.to_i
        end
      when nil
        generate_key
      else
        raise ArgumentError, "Invalid input. Must be hex, decimal, or bytestring."
      end
    end

    # Memoizes and returns 0x-prefixed hex
    #
    # @see {Eth::Refinements::Conversions::String#to_prefixed_hex}
    def to_prefixed_hex
      @prefixed_hex ||= hex.to_prefixed_hex
    end

    # Memoizes and returns zpadded hex
    #
    # @see {Eth::Refinements::Conversions::String#zpad}
    def to_zpadded_hex(length = 32)
      binding.break
      @zpadded_hex ||= hex.zpad(length)
    end

    # Memoizes and returns zpadded bytes
    #
    # @see {Eth::Refinements::Conversions::String#zpad}
    def to_zpadded_bytes(length = 32)
      @zpadded_bytes ||= bytes.zpad(length)
    end

    private

    # Generates a random 16 char hexa-decimal String
    def generate_key
      @hex = SecureRandom.hex(16)
      @bytes = hex.to_bytes
      @integer = hex.hex
    end
  end
end
