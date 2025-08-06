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

    # Provides a class to handle and parse common ABI types.
    class Type

      # Provides a specific parser error if type cannot be determined.
      class ParseError < StandardError; end

      # The base attribute, e.g., `string` or `bytes`.
      attr :base_type

      # The sub-type attribute, e.g., `256` as size of an uint256.
      attr :sub_type

      # The dimension attribute, e.g., `[10]` for an array of size 10.
      attr :dimensions

      # The components of a tuple type.
      attr :components

      # The name of tuple component.
      attr :name

      # Create a new Type object for base types, sub types, and dimensions.
      # Should not be used; use {Type.parse} instead.
      #
      # @param base_type [String] the base-type attribute.
      # @param sub_type [String] the sub-type attribute.
      # @param dimensions [Array] the dimension attribute.
      # @param components [Array] the components attribute.
      # @param component_name [String] the tuple component's name.
      # @return [Eth::Abi::Type] an ABI type object.
      def initialize(base_type, sub_type, dimensions, components = nil, component_name = nil)
        sub_type = sub_type.to_s
        @base_type = base_type
        @sub_type = sub_type
        @dimensions = dimensions
        @components = components
        @name = component_name
      end

      # Converts the self.parse method into a constructor.
      konstructor :parse

      # Attempts to parse a string containing a common Solidity type.
      # Creates a new Type upon success (using konstructor).
      #
      # @param type [String] a common Solidity type.
      # @param components [Array] the components attribute.
      # @param component_name [String] the tuple component's name.
      # @return [Eth::Abi::Type] a parsed Type object.
      # @raise [ParseError] if it fails to parse the type.
      def parse(type, components = nil, component_name = nil)
        if type.is_a?(Type)
          @base_type = type.base_type
          @sub_type = type.sub_type
          @dimensions = type.dimensions
          @components = type.components
          @name = type.name
          return
        end

        # ensure the type string is reasonable before attempting to parse
        raise ParseError, "Invalid type format" unless type.is_a? String

        if type.start_with?("tuple(") || type.start_with?("(")
          tuple_str = type.start_with?("tuple(") ? type : "tuple#{type}"
          inner, rest = extract_tuple(tuple_str)
          inner_types = split_tuple_types(inner)
          inner_types.each { |t| Type.parse(t) }
          base_type = "tuple"
          sub_type = ""
          dimension = rest
          components ||= inner_types.map { |t| { "type" => t } }
        else
          match = /\A([a-z]+)([0-9]*x?[0-9]*)((?:\[\d+\]|\[\])*)\z/.match(type)
          raise ParseError, "Invalid type format" unless match
          _, base_type, sub_type, dimension = match.to_a
          sub_type = "256" if %w[uint int].include?(base_type) && sub_type.empty?
        end

        # type dimension can only be numeric or empty for dynamic arrays
        dims = dimension.scan(/\[\d+\]|\[\]/)
        raise ParseError, "Unknown characters found in array declaration" if dims.join != dimension

        # enforce base types
        validate_base_type base_type, sub_type

        # return a new Type (using konstructor)
        sub_type = sub_type.to_s
        @base_type = base_type
        @sub_type = sub_type
        @dimensions = dims.map { |x| x == "[]" ? 0 : x[1...-1].to_i }
        @components = components.map { |component| Abi::Type.parse(component["type"], component.dig("components"), component.dig("name")) } if components&.any?
        @name = component_name
      end

      # Creates a new uint256 type used for size.
      #
      # @return [Eth::Abi::Type] a uint256 size type.
      def self.size_type
        @size_type ||= new("uint", 256, [])
      end

      # Compares two types for their attributes.
      #
      # @param another_type [Eth::Abi::Type] another type to be compared.
      # @return [Boolean] true if all attributes match.
      def ==(another_type)
        base_type == another_type.base_type and
          sub_type == another_type.sub_type and
          dimensions == another_type.dimensions
      end

      # Computes the size of a type if possible.
      #
      # @return [Integer] the size of the type; or nil if not available.
      def size
        s = nil
        if dimensions.empty?
          if !(["string", "bytes", "tuple"].include?(base_type) and sub_type.empty?)
            s = 32
          elsif base_type == "tuple" and components&.none?(&:dynamic?)
            s = components.sum(&:size)
          end
        elsif dimensions.last != 0 and !nested_sub.dynamic?
          s = dimensions.last * nested_sub.size
        end
        @size ||= s
      end

      # Helpes to determine whether array is of dynamic size.
      #
      # @return [Boolean] true if array is of dynamic size.
      def dynamic?
        size.nil?
      end

      # Types can have nested sub-types in arrays.
      #
      # @return [Eth::Abi::Type] nested sub-type.
      def nested_sub
        @nested_sub ||= self.class.new(base_type, sub_type, dimensions[0...-1], components, name)
      end

      # Allows exporting the type as string.
      #
      # @return [String] the type string.
      def to_s
        if base_type == "tuple"
          "(" + components.map(&:to_s).join(",") + ")" + (dimensions.size > 0 ? dimensions.map { |x| "[#{x == 0 ? "" : x}]" }.join : "")
        elsif dimensions.empty?
          if %w[string bytes].include?(base_type) and sub_type.empty?
            base_type
          else
            "#{base_type}#{sub_type}"
          end
        else
          "#{base_type}#{sub_type}#{dimensions.map { |x| "[#{x == 0 ? "" : x}]" }.join}"
        end
      end

      private

      # Validates all known base types and raises if an issue occurs.
      def validate_base_type(base_type, sub_type)
        case base_type
        when "string"

          # string can not have any suffix
          raise ParseError, "String type must have no suffix or numerical suffix" unless sub_type.empty?
        when "bytes"

          # bytes can be no longer than 32 bytes
          raise ParseError, "Maximum 32 bytes for fixed-length string or bytes" unless sub_type.empty? or (sub_type.to_i <= 32 and sub_type.to_i > 0)
        when "tuple"

          # tuples can not have any suffix
          raise ParseError, "Tuple type must have no suffix or numerical suffix" unless sub_type.empty?
        when "uint", "int"

          # integers must have a numerical suffix
          raise ParseError, "Integer type must have numerical suffix" unless sub_type =~ /\A[0-9]+\z/

          # integer size must be valid
          size = sub_type.to_i
          raise ParseError, "Integer size out of bounds" unless size >= 8 and size <= 256
          raise ParseError, "Integer size must be multiple of 8" unless size % 8 == 0
        when "ureal", "real", "fixed", "ufixed"

          # floats must have valid dimensional suffix
          raise ParseError, "Real type must have suffix of form <size>x<decimals>, e.g. 128x128" unless sub_type =~ /\A[0-9]+x[0-9]+\z/
          size, decimals = sub_type.split("x").map(&:to_i)
          total = size + decimals
          raise ParseError, "Real size out of bounds (max 32 bytes)" unless total >= 8 and total <= 256
          raise ParseError, "Real size must be multiples of 8" unless size % 8 == 0
        when "hash"

          # hashs must have numerical suffix
          raise ParseError, "Hash type must have numerical suffix" unless sub_type =~ /\A[0-9]+\z/
        when "address"

          # addresses cannot have any suffix
          raise ParseError, "Address cannot have suffix" unless sub_type.empty?
        when "bool"

          # booleans cannot have any suffix
          raise ParseError, "Bool cannot have suffix" unless sub_type.empty?
        else

          # we cannot parse arbitrary types such as 'decimal' or 'hex'
          raise ParseError, "Unknown base type"
        end
      end

      # Extracts the inner type list and trailing dimensions from an inline tuple definition.
      def extract_tuple(type)
        idx = 6 # skip "tuple("
        depth = 1
        while idx < type.length && depth > 0
          case type[idx]
          when "("
            depth += 1
          when ")"
            depth -= 1
          end
          idx += 1
        end
        raise ParseError, "Invalid tuple format" unless depth.zero?
        inner = type[6...(idx - 1)]
        rest = type[idx..] || ""
        [inner, rest]
      end

      # Splits a tuple component list into individual type strings, handling nested tuples.
      def split_tuple_types(str)
        types = []
        depth = 0
        current = ""
        str.each_char do |ch|
          case ch
          when "("
            depth += 1
            current << ch
          when ")"
            depth -= 1
            current << ch
          when ","
            if depth.zero?
              types << current
              current = ""
            else
              current << ch
            end
          else
            current << ch
          end
        end
        types << current unless current.empty?
        types
      end
    end
  end
end
