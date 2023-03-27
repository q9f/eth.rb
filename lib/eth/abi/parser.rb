# Copyright (c) 2016-2023 The Ruby-Eth Contributors
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
    BASE_TYPES = /([a-z]*)([0-9]*x?[0-9]*)((\[[0-9]*\])*)/
    TUPLE_TYPES = /^\((.*)\)((\[[0-9]*\])*)/x

    # Provides an ABI type parser.
    module Parser
      extend self

      # Provides a specific parser error if type cannot be determined.
      class ParseError < StandardError; end

      # Attempts to parse a given type.
      #
      # @param type [String] a type to parse.
      # @return [MetaType] a parsed type.
      # @raise [ParserError] if parsing fails.
      def parse(type)
        return type if type.kind_of? MetaType

        if type =~ TUPLE_TYPES
          sub_types = parse_tuple_type($1)
          dimension = parse_dimension($2)
          parsed_types = sub_types.map { |t| parse(t) }
          return parse_array_type(TupleType.new(parsed_types), dimension)
        end

        base_type, sub_type, dimension = parse_base_type(type)
        validate_base_type(base_type, sub_type)

        sub_type = case base_type
          when "address"
            AddressType.new
          when "bool"
            BooleanType.new
          when "bytes"
            sub_type ? FixedBytesType.new(sub_type) : BytesType.new
          when "int"
            IntType.new(sub_type.to_i)
          when "string"
            StringType.new
          when "uint"
            UIntType.new(sub_type.to_i)
          else
            raise ParseError, "Unknown base type: #{base_type}"
          end
        # @TODO
        parse_array_type(sub_type, dimension)
      end

      # Parses types for their base-type, sub-type, and dimension (if any).
      def parse_base_type(str)
        _, base_type, sub_type, dimension = BASE_TYPES.match(str).to_a
        sub_type = sub_type == "" ? nil : sub_type.to_i
        dimension = parse_dimension(dimension)
        [base_type, sub_type, dimension]
      end

      # Parses the dimensions of array types.
      def parse_dimension(str)
        dims = str.scan(/\[[0-9]*\]/)
        dims = dims.map do |d|
          size = d[1...-1]
          size == "" ? -1 : size.to_i
        end
        return dims
      end

      # Parses the type of an array.
      def parse_array_type(sub_type, dimension)
        return sub_type if dimension.first.nil?
        sub_type = if dimension.first == -1
            ArrayType.new(sub_type)
          else
            FixedArrayType.new(sub_type, dimension)
          end
        return sub_type
      end

      # Parses the types of a tuple.
      def parse_tuple_type(str)
        depth = 0
        collected = []
        current = ""

        str.each_char do |c|
          case c
          when "("
            depth += 1
            current += c
          when ")"
            depth -= 1
            current += c
          when ","
            if depth == 0
              collected << current
              current = ""
            else
              current += c
            end
          else
            current += c
          end
        end
        collected << current unless current.empty?
        return collected
      end

      # Validates all known base types and raises if an issue occurs.
      def validate_base_type(base_type, sub_type)
        case base_type
        when "string"

          # string can not have any suffix
          raise ParseError, "String type must have no suffix or numerical suffix" if sub_type
        when "bytes"

          # bytes can be no longer than 32 bytes
          raise ParseError, "Maximum 32 bytes for fixed-length string or bytes" unless sub_type.empty? || sub_type.to_i <= 32
        when "tuple"

          # tuples can not have any suffix
          raise ParseError, "Tuple type must have no suffix or numerical suffix" unless sub_type.empty?
        when "uint", "int"

          # integers must have a numerical suffix
          raise ParseError, "Integer type must have numerical suffix" unless sub_type

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
          raise ParseError, "Unknown base type: #{base_type}"
        end
      end
    end
  end
end
