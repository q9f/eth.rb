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

    # Encapsulates the module for non-standard packed encoding used in Solidity.
    module Packed

      # Provides a utility module to assist encoding ABIs.
      module Encoder
        extend self

        # Encodes a specific value, either static or dynamic in non-standard
        # packed encoding mode.
        #
        # @param type [Eth::Abi::Type] type to be encoded.
        # @param arg [String|Number] value to be encoded.
        # @return [String] the packed encoded type.
        # @raise [EncodingError] if value does not match type.
        # @raise [ArgumentError] if encoding fails for type.
        def type(type, arg)
          case type
          when /^uint(\d+)$/
            uint(arg, $1.to_i / 8)
          when /^int(\d+)$/
            int(arg, $1.to_i / 8)
          when "bool"
            bool(arg)
          when /^ureal(\d+)x(\d+)$/, /^ufixed(\d+)x(\d+)$/
            ufixed(arg, $1.to_i / 8, $2.to_i)
          when /^real(\d+)x(\d+)$/, /^fixed(\d+)x(\d+)$/
            fixed(arg, $1.to_i / 8, $2.to_i)
          when "string"
            string(arg)
          when /^bytes(\d+)$/
            bytes(arg, $1.to_i)
          when "bytes"
            string(arg)
          when /^tuple\((.+)\)$/
            tuple($1.split(","), arg)
          when /^hash(\d+)$/
            hash(arg, $1.to_i / 8)
          when "address"
            address(arg)
          when /^(.+)\[\]$/
            array($1, arg)
          when /^(.+)\[(\d+)\]$/
            fixed_array($1, arg, $2.to_i)
          else
            raise EncodingError, "Unhandled type: #{type}"
          end
        end

        private

        # Properly encodes signed integers.
        def uint(value, byte_size)
          raise ArgumentError, "Don't know how to handle this input." unless value.is_a? Numeric
          raise ValueOutOfBounds, "Number out of range: #{value}" if value > Constant::UINT_MAX or value < Constant::UINT_MIN
          i = value.to_i
          Util.zpad_int i, byte_size
        end

        # Properly encodes signed integers.
        def int(value, byte_size)
          raise ArgumentError, "Don't know how to handle this input." unless value.is_a? Numeric
          raise ValueOutOfBounds, "Number out of range: #{value}" if value > Constant::INT_MAX or value < Constant::INT_MIN
          real_size = byte_size * 8
          i = value.to_i % 2 ** real_size
          Util.zpad_int i, byte_size
        end

        # Properly encodes booleans.
        def bool(value)
          raise EncodingError, "Argument is not bool: #{value}" unless value.instance_of? TrueClass or value.instance_of? FalseClass
          (value ? "\x01" : "\x00").b
        end

        # Properly encodes unsigned fixed-point numbers.
        def ufixed(value, byte_size, decimals)
          raise ArgumentError, "Don't know how to handle this input." unless value.is_a? Numeric
          raise ValueOutOfBounds, value unless value >= 0 and value < 2 ** decimals
          scaled_value = (value * (10 ** decimals)).to_i
          uint(scaled_value, byte_size)
        end

        # Properly encodes signed fixed-point numbers.
        def fixed(value, byte_size, decimals)
          raise ArgumentError, "Don't know how to handle this input." unless value.is_a? Numeric
          raise ValueOutOfBounds, value unless value >= -2 ** (decimals - 1) and value < 2 ** (decimals - 1)
          scaled_value = (value * (10 ** decimals)).to_i
          int(scaled_value, byte_size)
        end

        # Properly encodes byte(-string)s.
        def bytes(value, length)
          raise EncodingError, "Expecting String: #{value}" unless value.instance_of? String
          value = handle_hex_string value, length
          raise ArgumentError, "Value must be a string of length #{length}" unless value.is_a?(String) && value.bytesize == length
          value.b
        end

        # Properly encodes (byte-)strings.
        def string(value)
          raise ArgumentError, "Value must be a string" unless value.is_a?(String)
          value.b
        end

        # Properly encodes tuples.
        def tuple(types, values)
          Abi.solidity_packed(types, values)
        end

        # Properly encodes hash-strings.
        def hash(value, byte_size)
          raise EncodingError, "Argument too long: #{value}" unless byte_size > 0 and byte_size <= 32
          hash_bytes = handle_hex_string value, byte_size
          hash_bytes.b
        end

        # Properly encodes addresses.
        def address(value)
          if value.is_a? Address

            # from checksummed address with 0x prefix
            Util.zpad_hex value.to_s[2..-1], 20
          elsif value.is_a? Integer

            # address from integer
            Util.zpad_int value, 20
          elsif value.size == 20

            # address from encoded address
            Util.zpad value, 20
          elsif value.size == 40

            # address from hexadecimal address
            Util.zpad_hex value, 20
          elsif value.size == 42 and value[0, 2] == "0x"

            # address from hexadecimal address with 0x prefix
            Util.zpad_hex value[2..-1], 20
          else
            raise EncodingError, "Could not parse address: #{value}"
          end
        end

        # Properly encodes dynamic-sized arrays.
        def array(type, values)
          values.map { |value| type(type, value) }.join.b
        end

        # Properly encodes fixed-size arrays.
        def fixed_array(type, values, size)
          raise ArgumentError, "Array size does not match" unless values.size == size
          array(type, values)
        end

        # The ABI encoder needs to be able to determine between a hex `"123"`
        # and a binary `"123"` string.
        def handle_hex_string(val, len)
          if Util.prefixed? val or
             (len === val.size / 2 and Util.hex? val)

            # There is no way telling whether a string is hex or binary with certainty
            # in Ruby. Therefore, we assume a `0x` prefix to indicate a hex string.
            # Additionally, if the string size is exactly the double of the expected
            # binary size, we can assume a hex value.
            Util.hex_to_bin val
          else

            # Everything else will be assumed binary or raw string.
            val.b
          end
        end
      end
    end
  end
end
