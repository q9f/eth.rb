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
require "bigdecimal"

# Provides the {Eth} module.
module Eth

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
  module Abi

    # Provides a utility module to assist encoding ABIs.
    module Encoder
      extend self

      # Encodes a specific value, either static or dynamic.
      #
      # @param type [Eth::Abi::Type] type to be encoded.
      # @param arg [String|Number] value to be encoded.
      # @return [String] the encoded type.
      # @raise [EncodingError] if value does not match type.
      def type(type, arg)
        if %w(string bytes).include? type.base_type and type.sub_type.empty? and type.dimensions.empty?
          raise EncodingError, "Argument must be a String" unless arg.instance_of? String
          arg = handle_hex_string arg, type

          # encodes strings and bytes
          size = type Type.size_type, arg.size
          padding = Constant::BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)
          "#{size}#{arg}#{padding}"
        elsif type.base_type == "tuple" && type.dimensions.empty?
          tuple arg, type
        elsif !type.dimensions.empty?
          encode_array type, arg
        else
          primitive_type type, arg
        end
      end

      # Encodes primitive types.
      #
      # @param type [Eth::Abi::Type] type to be encoded.
      # @param arg [String|Number] value to be encoded.
      # @return [String] the encoded primitive type.
      # @raise [EncodingError] if value does not match type.
      # @raise [ValueOutOfBounds] if value is out of bounds for type.
      # @raise [ArgumentError] if encoding fails for type.
      def primitive_type(type, arg)
        case type.base_type
        when "uint"
          uint arg, type
        when "int"
          int arg, type
        when "bool"
          bool arg
        when "ureal", "ufixed"
          ufixed arg, type
        when "real", "fixed"
          fixed arg, type
        when "string", "bytes"
          bytes arg, type
        when "tuple"
          tuple arg, type
        when "hash"
          hash arg, type
        when "address"
          address arg
        else
          raise EncodingError, "Unhandled type: #{type.base_type} #{type.sub_type}"
        end
      end

      private

      # Properly encodes unsigned integers.
      def uint(arg, type)
        arg = coerce_number arg
        raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
        raise ValueOutOfBounds, "Number out of range: #{arg}" if arg > Constant::UINT_MAX or arg < Constant::UINT_MIN
        real_size = type.sub_type.to_i
        i = arg.to_i
        raise ValueOutOfBounds, arg unless i >= 0 and i < 2 ** real_size
        Util.zpad_int i
      end

      # Properly encodes signed integers.
      def int(arg, type)
        arg = coerce_number arg
        raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
        raise ValueOutOfBounds, "Number out of range: #{arg}" if arg > Constant::INT_MAX or arg < Constant::INT_MIN
        real_size = type.sub_type.to_i
        i = arg.to_i
        raise ValueOutOfBounds, arg unless i >= -2 ** (real_size - 1) and i < 2 ** (real_size - 1)
        Util.zpad_int(i % 2 ** 256)
      end

      # Properly encodes booleans.
      def bool(arg)
        raise EncodingError, "Argument is not bool: #{arg}" unless arg.instance_of? TrueClass or arg.instance_of? FalseClass
        Util.zpad_int(arg ? 1 : 0)
      end

      # Properly encodes unsigned fixed-point numbers.
      def ufixed(arg, type)
        arg = coerce_number arg
        raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
        high, low = type.sub_type.split("x").map(&:to_i)
        raise ValueOutOfBounds, arg unless arg >= 0 and arg < 2 ** high
        Util.zpad_int((arg * 2 ** low).to_i)
      end

      # Properly encodes signed fixed-point numbers.
      def fixed(arg, type)
        arg = coerce_number arg
        raise ArgumentError, "Don't know how to handle this input." unless arg.is_a? Numeric
        high, low = type.sub_type.split("x").map(&:to_i)
        raise ValueOutOfBounds, arg unless arg >= -2 ** (high - 1) and arg < 2 ** (high - 1)
        i = (arg * 2 ** low).to_i
        Util.zpad_int(i % 2 ** (high + low))
      end

      # Properly encodes byte-strings.
      def bytes(arg, type)
        raise EncodingError, "Expecting String: #{arg}" unless arg.instance_of? String
        arg = handle_hex_string arg, type

        if type.sub_type.empty?
          size = Util.zpad_int arg.size
          padding = Constant::BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)

          # variable length string/bytes
          "#{size}#{arg}#{padding}"
        else
          raise ValueOutOfBounds, arg unless arg.size <= type.sub_type.to_i
          padding = Constant::BYTE_ZERO * (32 - arg.size)

          # fixed length string/bytes
          "#{arg}#{padding}"
        end
      end

      # Properly encodes tuples.
      def tuple(arg, type)
        unless arg.is_a?(Hash) || arg.is_a?(Array)
          raise EncodingError, "Expecting Hash or Array: #{arg}"
        end
        raise EncodingError, "Expecting #{type.components.size} elements: #{arg}" unless arg.size == type.components.size
        arg = arg.transform_keys(&:to_s) if arg.is_a?(Hash) # because component_type.name is String

        static_size = 0
        type.components.each_with_index do |component, i|
          if type.components[i].dynamic?
            static_size += 32
          else
            static_size += Util.ceil32(type.components[i].size || 0)
          end
        end

        dynamic_offset = static_size
        offsets_and_static_values = []
        dynamic_values = []

        type.components.each_with_index do |component, i|
          component_type = type.components[i]
          if component_type.dynamic?
            offsets_and_static_values << type(Type.size_type, dynamic_offset)
            dynamic_value = type(component_type, arg.is_a?(Array) ? arg[i] : arg[component_type.name])
            dynamic_values << dynamic_value
            dynamic_offset += dynamic_value.size
          else
            offsets_and_static_values << type(component_type, arg.is_a?(Array) ? arg[i] : arg.fetch(component_type.name))
          end
        end

        offsets_and_static_values.join + dynamic_values.join
      end

      def coerce_number(arg)
        return arg if arg.is_a? Numeric
        return arg.to_i(0) if arg.is_a?(String) && arg.match?(/^-?(0x)?[0-9a-fA-F]+$/)
        return BigDecimal(arg) if arg.is_a?(String) && arg.match?(/^-?\d+(\.\d+)?$/)
        arg
      end

      # Encodes array values of any dimensionality.
      #
      # @param type [Eth::Abi::Type] the type describing the array.
      # @param values [Array] the Ruby values to encode.
      # @return [String] ABI encoded array payload.
      # @raise [EncodingError] if the value cardinality does not match static dimensions.
      def encode_array(type, values)
        raise EncodingError, "Expecting Array value" unless values.is_a?(Array)

        required_length = type.dimensions.last
        if required_length != 0 && values.size != required_length
          raise EncodingError, "Expecting #{required_length} elements: #{values.size} provided"
        end

        nested_sub = type.nested_sub

        if required_length.zero?
          encode_dynamic_array(nested_sub, values)
        else
          encode_static_array(nested_sub, values)
        end
      end

      # Encodes dynamic-sized arrays, including nested tuples.
      #
      # @param nested_sub [Eth::Abi::Type] the element type.
      # @param values [Array] elements to encode.
      # @return [String] ABI encoded dynamic array payload.
      def encode_dynamic_array(nested_sub, values)
        head = type(Type.size_type, values.size)
        element_heads, element_tails = encode_array_elements(nested_sub, values)
        head + element_heads + element_tails
      end

      # Encodes static-sized arrays, including nested tuples.
      #
      # @param nested_sub [Eth::Abi::Type] the element type.
      # @param values [Array] elements to encode.
      # @return [String] ABI encoded static array payload.
      def encode_static_array(nested_sub, values)
        element_heads, element_tails = encode_array_elements(nested_sub, values)
        element_heads + element_tails
      end

      # Encodes the head/tail portions for array elements.
      #
      # @param nested_sub [Eth::Abi::Type] the element type.
      # @param values [Array] elements to encode.
      # @return [Array<String, String>] head/tail encoded segments.
      def encode_array_elements(nested_sub, values)
        if nested_sub.dynamic?
          head = ""
          tail = ""
          offset = values.size * 32
          values.each do |value|
            encoded = type(nested_sub, value)
            head += type(Type.size_type, offset)
            tail += encoded
            offset += encoded.size
          end
          [head, tail]
        else
          [values.map { |value| type(nested_sub, value) }.join, ""]
        end
      end

      # Properly encodes hash-strings.
      def hash(arg, type)
        size = type.sub_type.to_i
        raise EncodingError, "Argument too long: #{arg}" unless size > 0 and size <= 32
        if arg.is_a? Integer

          # hash from integer
          Util.zpad_int arg
        elsif arg.size == size

          # hash from encoded hash
          Util.zpad arg, 32
        elsif arg.size == size * 2

          # hash from hexadecimal hash
          Util.zpad_hex arg
        else
          raise EncodingError, "Could not parse hash: #{arg}"
        end
      end

      # Properly encodes addresses.
      def address(arg)
        if arg.is_a? Address

          # from checksummed address with 0x prefix
          Util.zpad_hex arg.to_s[2..-1]
        elsif arg.is_a? Integer

          # address from integer
          Util.zpad_int arg
        elsif arg.size == 20

          # address from encoded address
          Util.zpad arg, 32
        elsif arg.size == 40

          # address from hexadecimal address
          Util.zpad_hex arg
        elsif arg.size == 42 and arg[0, 2] == "0x"

          # address from hexadecimal address with 0x prefix
          Util.zpad_hex arg[2..-1]
        else
          raise EncodingError, "Could not parse address: #{arg}"
        end
      end

      # The ABI encoder needs to be able to determine between a hex `"123"`
      # and a binary `"123"` string.
      def handle_hex_string(arg, type)
        if Util.prefixed? arg or
           (arg.size === type.sub_type.to_i * 2 and Util.hex? arg)

          # There is no way telling whether a string is hex or binary with certainty
          # in Ruby. Therefore, we assume a `0x` prefix to indicate a hex string.
          # Additionally, if the string size is exactly the double of the expected
          # binary size, we can assume a hex value.
          Util.hex_to_bin arg
        else

          # Everything else will be assumed binary or raw string.
          arg.b
        end
      end
    end
  end
end
