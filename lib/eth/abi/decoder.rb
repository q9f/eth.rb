# Copyright (c) 2016-2025 The Ruby-Eth Contributors
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

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
  module Abi

    # Provides a utility module to assist decoding ABIs.
    module Decoder
      extend self

      # Decodes a specific value, either static or dynamic.
      #
      # @param type [Eth::Abi::Type] type to be decoded.
      # @param arg [String] encoded type data string.
      # @return [String] the decoded data for the type.
      # @raise [DecodingError] if decoding fails for type.
      def type(type, arg)
        if %w(string bytes).include?(type.base_type) and type.sub_type.empty?
          # Case: decoding a string/bytes
          if type.dimensions.empty?
            l = Util.deserialize_big_endian_to_int arg[0, 32]
            data = arg[32..-1]
            raise DecodingError, "Wrong data size for string/bytes object" unless data.size == Util.ceil32(l)

            # decoded strings and bytes
            data[0, l]
            # Case: decoding array of string/bytes
          else
            l = Util.deserialize_big_endian_to_int arg[0, 32]
            raise DecodingError, "Wrong data size for dynamic array" unless arg.size >= 32 + 32 * l

            # Decode each element of the array
            (1..l).map do |i|
              pointer = Util.deserialize_big_endian_to_int arg[i * 32, 32] # Pointer to the size of the array's element
              raise DecodingError, "Offset out of bounds" if pointer < 32 * l || pointer > arg.size - 64
              data_l = Util.deserialize_big_endian_to_int arg[32 + pointer, 32] # length of the element
              raise DecodingError, "Offset out of bounds" if pointer + 32 + Util.ceil32(data_l) > arg.size
              type(Type.parse(type.base_type), arg[pointer + 32, Util.ceil32(data_l) + 32])
            end
          end
        elsif type.base_type == "tuple"
          offset = 0
          data = {}
          raise DecodingError, "Cannot decode tuples without known components" if type.components.nil?
          type.components.each do |c|
            if c.dynamic?
              pointer = Util.deserialize_big_endian_to_int arg[offset, 32] # Pointer to the size of the array's element
              data_len = Util.deserialize_big_endian_to_int arg[pointer, 32] # length of the element

              data[c.name] = type(c, arg[pointer, Util.ceil32(data_len) + 32])
              offset += 32
            else
              size = c.size
              data[c.name] = type(c, arg[offset, size])
              offset += size
            end
          end
          data
        elsif type.dynamic?
          l = Util.deserialize_big_endian_to_int arg[0, 32]
          nested_sub = type.nested_sub

          if nested_sub.dynamic?
            raise DecodingError, "Wrong data size for dynamic array" unless arg.size >= 32 + 32 * l
            offsets = (0...l).map do |i|
              off = Util.deserialize_big_endian_to_int arg[32 + 32 * i, 32]
              raise DecodingError, "Offset out of bounds" if off < 32 * l || off > arg.size - 64
              off
            end
            offsets.map { |off| type(nested_sub, arg[32 + off..]) }
          else
            raise DecodingError, "Wrong data size for dynamic array" unless arg.size >= 32 + nested_sub.size * l
            # decoded dynamic-sized arrays with static sub-types
            (0...l).map { |i| type(nested_sub, arg[32 + nested_sub.size * i, nested_sub.size]) }
          end
        elsif !type.dimensions.empty?
          l = type.dimensions.first
          nested_sub = type.nested_sub

          # decoded static-size arrays
          (0...l).map { |i| type(nested_sub, arg[nested_sub.size * i, nested_sub.size]) }
        else

          # decoded primitive types
          primitive_type type, arg
        end
      end

      # Decodes primitive types.
      #
      # @param type [Eth::Abi::Type] type to be decoded.
      # @param data [String] encoded primitive type data string.
      # @return [String] the decoded data for the type.
      # @raise [DecodingError] if decoding fails for type.
      def primitive_type(type, data)
        case type.base_type
        when "address"

          # decoded address with 0x-prefix
          Address.new(Util.bin_to_hex data[12..-1]).to_s.downcase
        when "string", "bytes"
          if type.sub_type.empty?
            size = Util.deserialize_big_endian_to_int data[0, 32]

            # decoded dynamic-sized array
            data[32..-1][0, size]
          else

            # decoded static-sized array
            data[0, type.sub_type.to_i]
          end
        when "hash"

          # decoded hash
          data[(32 - type.sub_type.to_i), type.sub_type.to_i]
        when "uint"

          # decoded unsigned integer
          Util.deserialize_big_endian_to_int data
        when "int"
          u = Util.deserialize_big_endian_to_int data
          i = u >= 2 ** (type.sub_type.to_i - 1) ? (u - 2 ** 256) : u

          # decoded integer
          i
        when "ureal", "ufixed"
          high, low = type.sub_type.split("x").map(&:to_i)

          # decoded unsigned fixed point numeric
          Util.deserialize_big_endian_to_int(data) * 1.0 / 2 ** low
        when "real", "fixed"
          high, low = type.sub_type.split("x").map(&:to_i)
          u = Util.deserialize_big_endian_to_int data
          i = u >= 2 ** (high + low - 1) ? (u - 2 ** (high + low)) : u

          # decoded fixed point numeric
          i * 1.0 / 2 ** low
        when "bool"

          # decoded boolean
          data[-1] == Constant::BYTE_ONE
        else
          raise DecodingError, "Unknown primitive type: #{type.base_type}"
        end
      end
    end
  end
end
