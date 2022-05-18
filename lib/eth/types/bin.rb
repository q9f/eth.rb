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
  
  # Subclass of {Num} that represents a binary string / bytestring.
  #
  # @see {Num}
  #
  # @see {https://github.com/q9f/secp256k1.cr/blob/master/src/secp256k1/num.cr}
  # @example Pass in a bytestring and convert to hex.
  #   Bin[Keccak256.digest('eh')].to_hex
  #     =>  
  # @example Pass in a serialized Keccak256 String and convert to 0x-hex Num[Util.keccak256('test')].to_prefixed_hex @example Pass in a serialized Keccak256 String and convert to 0x-hex @raise [ArgumentError] raised if input is a String but
  #   isn't hex or bytes, or if input is an Array but not
  #   a list of ascii-8bit numbers
  class Bin < Num
    # Instantiates a Num with {@hex} set to {SecureRandom.hex(16)}
    #   then uses conversion methods to set the bytestring and
    #   {Integer}.
    def initialize(input)
      @input = input

      @bin = input.b
      @hex = Hex[bin.unpack1("H*")]
      @dec = Dec[hex.input.to_i(16)]
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
