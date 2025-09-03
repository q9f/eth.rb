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
        elsif type.dynamic?
          l = Util.deserialize_big_endian_to_int arg[0, 32]
          nested_sub = type.nested_sub

          if nested_sub.base_type == "tuple"
            # Special handling for tuple arrays - decode until no more data
            result = []
            current_pos = 32  # Skip the length field

            # Try to decode as many tuples as possible
            while current_pos < arg.size
              begin
                # Try to decode a tuple at the current position
                tuple_data = arg[current_pos..-1]
                if tuple_data.size < 32
                  break  # Not enough data for even one field
                end

                # Decode one tuple - use the original tuple type instead of nested_sub
                tuple_type = Eth::Abi::Type.new("tuple", "", [], type.components, nil)
                tuple = type(tuple_type, tuple_data)
                result << tuple

                # Calculate tuple size based on components
                tuple_size = calculate_tuple_size(nested_sub)
                current_pos += tuple_size

                # Safety check to prevent infinite loops
                if current_pos >= arg.size
                  break
                end
              rescue => e
                # If we can't decode more tuples, stop
                break
              end
            end
            result
          elsif nested_sub.dynamic?
            raise DecodingError, "Wrong data size for dynamic array" unless arg.size >= 32 + 32 * l
            offsets = (0...l).map do |i|
              off = Util.deserialize_big_endian_to_int arg[32 + 32 * i, 32]
              raise DecodingError, "Offset out of bounds" if off < 32 * l || off > arg.size - 64
              off
            end

            # For dynamic arrays with dynamic sub-types, we need to calculate the data boundaries
            # Each element starts at its offset and continues until the next offset or end of data
            result = []
            offsets.each_with_index do |off, i|
              if i < offsets.length - 1
                # Use the next offset as the boundary
                next_off = offsets[i + 1]
                data_length = next_off - off
                result << type(nested_sub, arg[32 + off, data_length])
              else
                # For the last element, use the remaining data
                result << type(nested_sub, arg[32 + off..])
              end
            end
            result
          else
            raise DecodingError, "Wrong data size for dynamic array" unless arg.size >= 32 + nested_sub.size * l
            # decoded dynamic-sized arrays with static sub-types
            (0...l).map { |i| type(nested_sub, arg[32 + nested_sub.size * i, nested_sub.size]) }
          end
        elsif type.base_type == "tuple"
          offset = 0
          result = []
          raise DecodingError, "Cannot decode tuples without known components" if type.components.nil?
          type.components.each_with_index do |c, i|
            if c.dynamic?
              pointer = Util.deserialize_big_endian_to_int arg[offset, 32]
              next_offset = if i + 1 < type.components.size
                  Util.deserialize_big_endian_to_int arg[offset + 32, 32]
                else
                  arg.size
                end
              raise DecodingError, "Offset out of bounds" if pointer > arg.size || next_offset > arg.size || next_offset < pointer
              result << type(c, arg[pointer, next_offset - pointer])
              offset += 32
            else
              size = c.size
              raise DecodingError, "Offset out of bounds" if offset + size > arg.size
              result << type(c, arg[offset, size])
              offset += size
            end
          end
          result
        elsif !type.dimensions.empty?
          l = type.dimensions.first
          nested_sub = type.nested_sub

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
            # decoded static-size arrays with static sub-types
            (0...l).map { |i| type(nested_sub, arg[nested_sub.size * i, nested_sub.size]) }
          end
        else

          # decoded primitive types
          primitive_type type, arg
        end
      end

      # Calculates the size of a tuple based on its components.
      #
      # @param type [Eth::Abi::Type] the tuple type
      # @return [Integer] the size of the tuple in bytes
      def calculate_tuple_size(type)
        return 0 if type.components.nil?

        # Calculate the total size based on all components
        total_size = 0
        type.components.each do |component|
          if component.dynamic?
            # Dynamic components use 32 bytes for the offset
            total_size += 32
          else
            # Static components use their defined size
            component_size = component.size || 32
            total_size += component_size
          end
        end

        total_size
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
