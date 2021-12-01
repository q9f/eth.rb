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

module Eth

  # Defines handy tools for the `Eth` gem for convenience.
  module Utils
    extend self

    def public_key_to_address bin
      bytes = keccak256(bin[1..-1])[-20..-1 ]
      address = bin_to_prefixed_hex bytes # @TODO Checksummed
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

    def hex_to_bin hex
      raise TypeError, "Value must be an instance of String" unless hex.instance_of?(String)
      raise TypeError, "Non-hexadecimal digit found" unless is_hex? hex
      [hex].pack('H*')
    end

    def prefix_hex hex
      return hex if is_prefixed? hex
      return "0x#{hex}"
    end

    def remove_hex_prefix str
      return str[2..-1] if is_prefixed? str
      return str
    end

    def bin_to_prefixed_hex bin
      prefix_hex bin_to_hex bin
    end

    def is_hex? str
      str = remove_hex_prefix str
      str.match /\A[0-9a-fA-F]*\z/
    end

    def is_prefixed? hex
      hex.match /\A0x/
    end
  end
end
