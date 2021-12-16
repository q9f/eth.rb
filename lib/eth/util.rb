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

require 'digest/keccak'

# Provides the `Eth` module.
module Eth

  # Defines handy tools for the `Eth` gem for convenience.
  module Utils
    extend self

    # Generates an Ethereum address from a given compressed or
    # uncompressed binary or hexadecimal public key string.
    #
    # @param str [String] the public key to be converted.
    # @return [Eth::Address] an Ethereum address.
    def public_key_to_address str
      str = hex_to_bin str if is_hex? str
      bytes = keccak256(str[1..-1])[-20..-1 ]
      Eth::Address.new bin_to_prefixed_hex bytes
    end

    # Hashes a string with the Keccak-256 algorithm.
    #
    # @param str [String] a string to be hashed.
    # @return [String] a Keccak-256 hash of the given string.
    def keccak256 str
      Digest::Keccak.new(256).digest str
    end

    # Unpacks a binary string to a hexa-decimal string.
    #
    # @param bin [String] a binary string to be unpacked.
    # @return [String] a hexa-decimal string.
    # @raise [TypeError] if value is not a string.
    def bin_to_hex bin
      raise TypeError, "Value must be an instance of String" unless bin.instance_of? String
      bin.unpack("H*").first
    end

    # Packs a hexa-decimal string into a binary string. Also works with
    # `0x`-prefixed strings.
    #
    # @param hex [String] a hexa-decimal string to be packed.
    # @return [String] a packed binary string.
    # @raise [TypeError] if value is not a string or string is not hex.
    def hex_to_bin hex
      raise TypeError, "Value must be an instance of String" unless hex.instance_of? String
      hex = remove_hex_prefix hex
      raise TypeError, "Non-hexadecimal digit found" unless is_hex? hex
      [hex].pack('H*')
    end

    # Prefixes a hexa-decimal string with `0x`.
    #
    # @param hex [String] a hex-string to be prefixed.
    # @return [String] a prefixed hex-string.
    def prefix_hex hex
      return hex if is_prefixed? hex
      return "0x#{hex}"
    end

    # Removes the `0x` prefix of a hexa-decimal string.
    #
    # @param hex [String] a prefixed hex-string.
    # @return [String] an unprefixed hex-string.
    def remove_hex_prefix hex
      return hex[2..-1] if is_prefixed? hex
      return hex
    end

    # Unpacks a binary string to a prefixed hexa-decimal string.
    #
    # @param bin [String] a binary string to be unpacked.
    # @return [String] a prefixed hexa-decimal string.
    def bin_to_prefixed_hex bin
      prefix_hex bin_to_hex bin
    end

    # Checks if a string is hex-adecimal.
    #
    # @param str [String] a string to be checked.
    # @return [String] a match if true; nil if not.
    def is_hex? str
      str = remove_hex_prefix str
      str.match /\A[0-9a-fA-F]*\z/
    end

    # Checks if a string is prefixed with `0x`.
    #
    # @param hex [String] a string to be checked.
    # @return [String] a match if true; nil if not.
    def is_prefixed? hex
      hex.match /\A0x/
    end
  end
end
