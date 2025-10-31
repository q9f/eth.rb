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
        if !type.dimensions.empty?
          dimensions = type.dimensions.reverse
          outermost_length = dimensions.first
          nested_sub = type.nested_sub

          if outermost_length.zero?
            l = Util.deserialize_big_endian_to_int arg[0, 32]

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
              (0...l).map { |i| type(nested_sub, arg[32 + nested_sub.size * i, nested_sub.size]) }
            end
          else
            l = outermost_length

            if nested_sub.dynamic?
              raise DecodingError, "Wrong data size for static array" unless arg.size >= 32 * l
              offsets = (0...l).map do |i|
                off = Util.deserialize_big_endian_to_int arg[32 * i, 32]
                raise DecodingError, "Offset out of bounds" if off < 32 * l || off > arg.size - 32
                off
              end
              offsets.each_with_index.map do |off, i|
                size = (i + 1 < offsets.length ? offsets[i + 1] : arg.size) - off
                type(nested_sub, arg[off, size])
              end
            else
              (0...l).map { |i| type(nested_sub, arg[nested_sub.size * i, nested_sub.size]) }
            end
          end
        elsif %w(string bytes).include?(type.base_type) and type.sub_type.empty?
          l = Util.deserialize_big_endian_to_int arg[0, 32]
          data = arg[32..-1]
          raise DecodingError, "Wrong data size for string/bytes object" if data.size < Util.ceil32(l)

          # decoded strings and bytes
          data[0, l]
        elsif type.base_type == "tuple" && type.dimensions.empty?
          raise DecodingError, "Cannot decode tuples without known components" if type.components.nil?

          # Determine the head (static portion) offsets for each component once so we
          # can safely resolve dynamic pointers regardless of the component order.
          component_offsets = []
          head_offset = 0
          type.components.each do |component|
            component_offsets << head_offset
            head_offset += component.dynamic? ? 32 : component.size
          end

          result = []

          type.components.each_with_index do |c, i|
            offset = component_offsets[i]
            if c.dynamic?
              pointer = Util.deserialize_big_endian_to_int arg[offset, 32]
              raise DecodingError, "Offset out of bounds" if pointer < head_offset || pointer > arg.size

              next_pointer = nil
              ((i + 1)...type.components.size).each do |j|
                next_component = type.components[j]
                next unless next_component.dynamic?

                next_pointer = Util.deserialize_big_endian_to_int arg[component_offsets[j], 32]
                break
              end

              pointer_limit = next_pointer || arg.size
              raise DecodingError, "Offset out of bounds" if pointer_limit > arg.size || pointer_limit < pointer || pointer_limit < head_offset

              result << type(c, arg[pointer, pointer_limit - pointer])
            else
              size = c.size
              raise DecodingError, "Offset out of bounds" if offset + size > arg.size
              result << type(c, arg[offset, size])
            end
          end
          result
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
            decoded = data[32..-1][0, size]
            decoded.force_encoding(Encoding::UTF_8)
            decoded
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
