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

require "digest/keccak"

# Provides the {Eth} module.
module Eth

  # Defines handy tools for the {Eth} gem for convenience.
  module Util
    extend self

    # Generates an Ethereum address from a given compressed or
    # uncompressed binary or hexadecimal public key string.
    #
    # @param str [String] the public key to be converted.
    # @return [Eth::Address] an Ethereum address.
    def public_key_to_address(str)
      str = hex_to_bin str if is_hex? str
      bytes = keccak256(str[1..-1])[-20..-1]
      Address.new bin_to_prefixed_hex bytes
    end

    # Hashes a string with the Keccak-256 algorithm.
    #
    # @param str [String] a string to be hashed.
    # @return [String] a Keccak-256 hash of the given string.
    def keccak256(str)
      Digest::Keccak.new(256).digest str
    end

    # Unpacks a binary string to a hexa-decimal string.
    #
    # @param bin [String] a binary string to be unpacked.
    # @return [String] a hexa-decimal string.
    # @raise [TypeError] if value is not a string.
    def bin_to_hex(bin)
      raise TypeError, "Value must be an instance of String" unless bin.instance_of? String
      bin.unpack("H*").first
    end

    # Packs a hexa-decimal string into a binary string. Also works with
    # `0x`-prefixed strings.
    #
    # @param hex [String] a hexa-decimal string to be packed.
    # @return [String] a packed binary string.
    # @raise [TypeError] if value is not a string or string is not hex.
    def hex_to_bin(hex)
      raise TypeError, "Value must be an instance of String" unless hex.instance_of? String
      hex = remove_hex_prefix hex
      raise TypeError, "Non-hexadecimal digit found" unless is_hex? hex
      [hex].pack("H*")
    end

    # Prefixes a hexa-decimal string with `0x`.
    #
    # @param hex [String] a hex-string to be prefixed.
    # @return [String] a prefixed hex-string.
    def prefix_hex(hex)
      return hex if is_prefixed? hex
      return "0x#{hex}"
    end

    # Removes the `0x` prefix of a hexa-decimal string.
    #
    # @param hex [String] a prefixed hex-string.
    # @return [String] an unprefixed hex-string.
    def remove_hex_prefix(hex)
      return hex[2..-1] if is_prefixed? hex
      return hex
    end

    # Unpacks a binary string to a prefixed hexa-decimal string.
    #
    # @param bin [String] a binary string to be unpacked.
    # @return [String] a prefixed hexa-decimal string.
    def bin_to_prefixed_hex(bin)
      prefix_hex bin_to_hex bin
    end

    # Checks if a string is hex-adecimal.
    #
    # @param str [String] a string to be checked.
    # @return [String] a match if true; `nil` if not.
    def is_hex?(str)
      return false unless str.is_a? String
      str = remove_hex_prefix str
      str.match /\A[0-9a-fA-F]*\z/
    end

    # Checks if a string is prefixed with `0x`.
    #
    # @param hex [String] a string to be checked.
    # @return [String] a match if true; `nil` if not.
    def is_prefixed?(hex)
      hex.match /\A0x/
    end

    # Serializes an unsigned integer to big endian.
    #
    # @param num [Integer] unsigned integer to be serialized.
    # @return [String] serialized big endian integer string.
    # @raise [ArgumentError] if unsigned integer is out of bounds.
    def serialize_int_to_big_endian(num)
      num = num.to_i(16) if is_hex? num
      unless num.is_a? Integer and num >= 0 and num <= Constant::UINT_MAX
        raise ArgumentError, "Integer invalid or out of range: #{num}"
      end
      Rlp::Sedes.big_endian_int.serialize num
    end

    # Converts an integer to big endian.
    #
    # @param num [Integer] integer to be converted.
    # @return [String] packed, big-endian integer string.
    def int_to_big_endian(num)
      hex = num.to_s(16) unless is_hex? num
      hex = "0#{hex}" if hex.size.odd?
      hex_to_bin hex
    end

    # Deserializes big endian data string to integer.
    #
    # @param str [String] serialized big endian integer string.
    # @return [Integer] an deserialized unsigned integer.
    def deserialize_big_endian_to_int(str)
      Rlp::Sedes.big_endian_int.deserialize str.sub(/\A(\x00)+/, "")
    end

    # Converts a big endian to an interger.
    #
    # @param str [String] big endian to be converted.
    # @return [Integer] an unpacked integer number.
    def big_endian_to_int(str)
      str.unpack("H*").first.to_i(16)
    end

    # Converts a binary string to bytes.
    #
    # @param str [String] binary string to be converted.
    # @return [Object] the string bytes.
    def str_to_bytes(str)
      is_bytes?(str) ? str : str.b
    end

    # Converts bytes to a binary string.
    #
    # @param bin [Object] bytes to be converted.
    # @return [String] a packed binary string.
    def bytes_to_str(bin)
      bin.unpack("U*").pack("U*")
    end

    # Checks if a string is a byte-string.
    #
    # @param str [String] a string to check.
    # @return [Boolean] true if it's an ASCII-8bit encoded byte-string.
    def is_bytes?(str)
      str && str.instance_of?(String) && str.encoding.name == Constant::BINARY_ENCODING
    end

    # Checks if the given item is a string primitive.
    #
    # @param item [Object] the item to check.
    # @return [Boolean] true if it's a string primitive.
    def is_primitive?(item)
      item.instance_of?(String)
    end

    # Checks if the given item is a list.
    #
    # @param item [Object] the item to check.
    # @return [Boolean] true if it's a list.
    def is_list?(item)
      !is_primitive?(item) && item.respond_to?(:each)
    end

    # Ceil and integer to the next multiple of 32 bytes.
    #
    # @param num [Integer] the number to ciel up.
    # @return [Integer] the ceiled to 32 integer.
    def ceil32(num)
      num % 32 == 0 ? num : (num + 32 - num % 32)
    end

    # Left-pad a number with a symbol.
    #
    # @param str [String] a serialized string to be padded.
    # @param sym [String] a symbol used for left-padding.
    # @param len [Integer] number of symbols for the final string.
    # @return [String] a left-padded serialized string of wanted size.
    def lpad(str, sym, len)
      return str if str.size >= len
      sym * (len - str.size) + str
    end

    # Left-pad a serialized string with zeros.
    #
    # @param str [String] a serialized string to be padded.
    # @param len [Integer] number of symbols for the final string.
    # @return [String] a zero-padded serialized string of wanted size.
    def zpad(str, len)
      lpad str, Constant::BYTE_ZERO, len
    end

    # Left-pad a hex number with zeros.
    #
    # @param hex [String] a hex-string to be padded.
    # @param len [Integer] number of symbols for the final string.
    # @return [String] a zero-padded serialized string of wanted size.
    def zpad_hex(hex, len = 32)
      zpad hex_to_bin(hex), len
    end

    # Left-pad an unsigned integer with zeros.
    #
    # @param num [Integer] an unsigned integer to be padded.
    # @param len [Integer] number of symbols for the final string.
    # @return [String] a zero-padded serialized string of wanted size.
    def zpad_int(num, len = 32)
      zpad serialize_int_to_big_endian(num), len
    end
  end
end
