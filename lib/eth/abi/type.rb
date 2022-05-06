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

      # Create a new Type object for base types, sub types, and dimensions.
      # Should not be used; use {Type.parse} instead.
      #
      # @param base_type [String] the base-type attribute.
      # @param sub_type [String] the sub-type attribute.
      # @param dimensions [Array] the dimension attribute.
      # @return [Eth::Abi::Type] an ABI type object.
      def initialize(base_type, sub_type, dimensions)
        sub_type = sub_type.to_s
        @base_type = base_type
        @sub_type = sub_type
        @dimensions = dimensions
      end

      # Converts the self.parse method into a constructor.
      konstructor :parse

      # Attempts to parse a string containing a common Solidity type.
      # Creates a new Type upon success (using konstructor).
      #
      # @param type [String] a common Solidity type.
      # @return [Eth::Abi::Type] a parsed Type object.
      # @raise [ParseError] if it fails to parse the type.
      def parse(type)
        _, base_type, sub_type, dimension = /([a-z]*)([0-9]*x?[0-9]*)((\[[0-9]*\])*)/.match(type).to_a

        # type dimension can only be numeric
        dims = dimension.scan(/\[[0-9]*\]/)
        raise ParseError, "Unknown characters found in array declaration" if dims.join != dimension

        # enforce base types
        validate_base_type base_type, sub_type

        # return a new Type (using konstructor)
        sub_type = sub_type.to_s
        @base_type = base_type
        @sub_type = sub_type
        @dimensions = dims.map { |x| x[1...-1].to_i }
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
          unless ["string", "bytes"].include?(base_type) and sub_type.empty?
            s = 32
          end
        else
          unless dimensions.last == 0
            unless nested_sub.is_dynamic?
              s = dimensions.last * nested_sub.size
            end
          end
        end
        @size ||= s
      end

      # Helpes to determine whether array is of dynamic size.
      #
      # @return [Boolean] true if array is of dynamic size.
      def is_dynamic?
        size.nil?
      end

      # Types can have nested sub-types in arrays.
      #
      # @return [Eth::Abi::Type] nested sub-type.
      def nested_sub
        @nested_sub ||= self.class.new(base_type, sub_type, dimensions[0...-1])
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
          raise ParseError, "Maximum 32 bytes for fixed-length string or bytes" unless sub_type.empty? || sub_type.to_i <= 32
        when "uint", "int"

          # integers must have a numerical suffix
          raise ParseError, "Integer type must have numerical suffix" unless sub_type =~ /\A[0-9]+\z/

          # integer size must be valid
          size = sub_type.to_i
          raise ParseError, "Integer size out of bounds" unless size >= 8 && size <= 256
          raise ParseError, "Integer size must be multiple of 8" unless size % 8 == 0
        when "ureal", "real", "fixed", "ufixed"

          # floats must have valid dimensional suffix
          raise ParseError, "Real type must have suffix of form <high>x<low>, e.g. 128x128" unless sub_type =~ /\A[0-9]+x[0-9]+\z/
          high, low = sub_type.split("x").map(&:to_i)
          total = high + low
          raise ParseError, "Real size out of bounds (max 32 bytes)" unless total >= 8 && total <= 256
          raise ParseError, "Real high/low sizes must be multiples of 8" unless high % 8 == 0 && low % 8 == 0
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
    end
  end
end
