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

require "rlp"
require "digest/keccak"

# Provides the `Eth` module.
module Eth

  # Defines handy tools for the `Eth` gem for convenience.
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
      Eth::Address.new bin_to_prefixed_hex bytes
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
    # @return [String] a match if true; nil if not.
    def is_hex?(str)
      str = remove_hex_prefix str
      str.match /\A[0-9a-fA-F]*\z/
    end

    # Checks if a string is prefixed with `0x`.
    #
    # @param hex [String] a string to be checked.
    # @return [String] a match if true; nil if not.
    def is_prefixed?(hex)
      hex.match /\A0x/
    end

    def encode_hex(b)
      RLP::Util.encode_hex b
    end

    def decode_hex(s)
      RLP::Util.decode_hex s
    end

    def big_endian_to_int(s)
      RLP::Sedes.big_endian_int.deserialize s.sub(/\A(\x00)+/, "")
    end

    def int_to_big_endian(n)
      RLP::Sedes.big_endian_int.serialize n
    end

    def remove_0x_head(s)
      s[0, 2] == "0x" ? s[2..-1] : s
    end

    def normalize_hex_without_prefix(s)
      if s[0, 2] == "0x"
        (s.size % 2 == 1 ? "0" : "") + s[2..-1]
      else
        s
      end
    end

    def ripemd160(x)
      Digest::RMD160.digest x
    end

    def hash160(x)
      ripemd160 sha256(x)
    end

    def hash160_hex(x)
      encode_hex hash160(x)
    end

    def ceil32(x)
      x % 32 == 0 ? x : (x + 32 - x % 32)
    end

    def zpad(x, l)
      lpad x, Abi::Constant::BYTE_ZERO, l
    end

    def zunpad(x)
      x.sub /\A\x00+/, ""
    end

    def zpad_int(n, l = 32)
      zpad encode_int(n), l
    end

    def zpad_hex(s, l = 32)
      zpad decode_hex(s), l
    end

    def int_to_addr(x)
      zpad_int x, 20
    end

    def encode_int(n)
      unless n.is_a?(Integer) && n >= 0 && n <= Abi::Constant::UINT_MAX
        raise ArgumentError, "Integer invalid or out of range: #{n}"
      end

      int_to_big_endian n
    end

    def decode_int(v)
      if v.size > 0 && (v[0] == BYTE_ZERO || v[0] == 0)
        raise ArgumentError, "No leading zero bytes allowed for integers"
      end

      big_endian_to_int v
    end

    def bytearray_to_int(arr)
      o = 0
      arr.each { |x| o = (o << 8) + x }
      o
    end

    def int_array_to_bytes(arr)
      arr.pack("C*")
    end

    def bytes_to_int_array(bytes)
      bytes.unpack("C*")
    end

    def coerce_to_int(x)
      if x.is_a?(Numeric)
        x
      elsif x.size == 40
        big_endian_to_int decode_hex(x)
      else
        big_endian_to_int x
      end
    end

    def coerce_to_bytes(x)
      if x.is_a?(Numeric)
        int_to_big_endian x
      elsif x.size == 40
        decode_hex(x)
      else
        x
      end
    end

    def coerce_addr_to_hex(x)
      if x.is_a?(Numeric)
        encode_hex zpad(int_to_big_endian(x), 20)
      elsif x.size == 40 || x.size == 0
        x
      else
        encode_hex zpad(x, 20)[-20..-1]
      end
    end

    def lpad(x, symbol, l)
      return x if x.size >= l
      symbol * (l - x.size) + x
    end
  end
end
