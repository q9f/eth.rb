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

# Provides the {Eth} module.
module Eth

  # Defines handy tools for encoding typed structured data as per EIP-712.
  # Ref: https://eips.ethereum.org/EIPS/eip-712
  module Eip712
    extend self

    # Provides a special typed-data error if data structure fails basic
    # verification.
    class TypedDataError < StandardError; end

    # Scans all dependencies of a given type recursively and returns
    # either all dependencies or none if not found.
    #
    # @param primary_type [String] the primary type which we want to scan.
    # @param types [Array] all existing types in the data structure.
    # @param result [Array] found results from previous recursions.
    # @return [Array] all dependent types for the given primary type.
    def type_dependencies(primary_type, types, result = [])
      if result.include? primary_type

        # ignore if we already have the give type in results
        return result
      elsif types[primary_type.to_sym].nil?

        # ignore if the type is not used, e.g., a string or address.
        return result
      else

        # we found something
        result.push primary_type

        # recursively look for further nested dependencies
        types[primary_type.to_sym].each do |t|
          nested_type = t[:type]
          # unpack arrays to their inner types to resolve dependencies
          if nested_type.end_with?("]")
            nested_type = nested_type.partition("[").first
          end
          dependency = type_dependencies nested_type, types, result
        end
        return result
      end
    end

    # Encode types as an EIP-712 confrom string, e.g.,
    # `MyType(string attribute)`.
    #
    # @param primary_type [String, Symbol] the type which we want to encode.
    # @param types [Array] all existing types in the data structure.
    # @return [String] an EIP-712 encoded type-string.
    # @raise [TypedDataError] if non-primary type found.
    def encode_type(primary_type, types)

      # get all used types
      all_dependencies = type_dependencies primary_type, types

      # remove primary types and sort the rest alphabetically; a Symbol
      # names the same type as its String
      filtered_dependencies = all_dependencies.map(&:to_s).uniq.delete_if { |type| type == primary_type.to_s }
      sorted_dependencies = filtered_dependencies.sort
      dependencies = [primary_type]
      sorted_dependencies.each do |sorted|
        dependencies.push sorted
      end

      # join them all in a string with types and field names
      result = ""
      dependencies.each do |type|

        # dependencies should not have non-primary types (such as string, address)
        raise TypedDataError, "Non-primary type found: #{type}!" if types[type.to_sym].nil?

        result += "#{type}("
        result += types[type.to_sym].map { |t| "#{t[:type]} #{t[:name]}" }.join(",")
        result += ")"
      end
      return result
    end

    # Hashes an EIP-712 confrom type-string.
    #
    # @param primary_type [String, Symbol] the type which we want to hash.
    # @param types [Array] all existing types in the data structure.
    # @return [String] a Keccak-256 hash of an EIP-712 encoded type-string.
    def hash_type(primary_type, types)
      encoded_type = encode_type primary_type, types
      return Util.keccak256 encoded_type
    end

    # Recursively ABI-encodes all data and types according to EIP-712.
    #
    # @param primary_type [String, Symbol] the primary type which we want to encode.
    # @param data [Array] the data in the data structure we want to encode.
    # @param types [Array] all existing types in the data structure.
    # @return [String] an ABI-encoded representation of the data and the types.
    def encode_data(primary_type, data, types)

      # first data field is the type hash
      encoded_types = ["bytes32"]
      encoded_values = [hash_type(primary_type, types)]

      # adds field contents
      types[primary_type.to_sym].each do |field|
        value = data[field[:name].to_sym]
        type = field[:type]
        if type.end_with?("]")

          # an array is one word: the hash of its encoded elements
          encoded_types.push "bytes32"
          encoded_values.push encode_array(type, value, types)
        elsif type == "string" || type == "bytes" || !types[type.to_sym].nil?
          encoded_types.push "bytes32"
          encoded_values.push encode_value(type, value, types)
        else
          encoded_types.push type
          encoded_values.push value
        end
      end

      # all data is abi-encoded
      return Abi.encode encoded_types, encoded_values
    end

    # Encodes a single value according to its type following EIP-712 rules.
    # Returns a 32-byte binary string.
    def encode_value(type, value, types)
      if type == "string"
        return Util.keccak256 value
      elsif type == "bytes"
        value = Util.hex_to_bin value
        return Util.keccak256 value
      elsif !types[type.to_sym].nil?
        nested = encode_data type, value, types
        return Util.keccak256 nested
      else
        # encode basic types via ABI to get 32-byte representation
        return Abi.encode([type], [value])
      end
    end

    # Encodes an array value as EIP-712 defines it: the Keccak-256 hash of
    # the concatenated encodings of its elements. Each element is encoded as
    # a member of the inner type would be: atomic values as 32-byte ABI
    # words, strings and bytes hashed, structs as their struct hash, and
    # nested arrays by this rule. A `nil` value is the empty array.
    #
    # @param type [String] the array type, e.g., `uint256[]` or `Person[2]`.
    # @param value [Array] the array elements, or `nil` for none.
    # @param types [Array] all existing types in the data structure.
    # @return [String] a 32-byte Keccak-256 hash of the encoded elements.
    # @raise [Abi::Type::ParseError] if the base type is neither a struct nor a valid ABI type, or a size is not a number.
    # @raise [Abi::EncodingError] if a fixed-size array holds another number of elements.
    def encode_array(type, value, types)
      bracket = type.rindex("[")
      inner_type = type.slice(0, bracket)
      length = type.slice((bracket + 1)...-1).to_i
      value = [] if value.nil?

      # rejects an invalid base type or size, also for an empty array: the ABI
      # parser checks atomic types, struct types get its rule for sizes
      base_type = type.partition("[").first
      if types[base_type.to_sym].nil?
        Abi::Type.parse type
      elsif !type.delete_prefix(base_type).match?(/\A(?:\[\d+\]|\[\])*\z/)
        raise Abi::Type::ParseError, "Invalid type format"
      end

      # a fixed-size array must hold exactly its declared number of elements
      if length != 0 && value.size != length
        raise Abi::EncodingError, "Expecting #{length} elements: #{value.size} provided"
      end

      # encodes each element as a member of the inner type
      encoded = value.map do |v|
        if inner_type.end_with?("]")
          encode_array inner_type, v, types
        else
          encode_value inner_type, v, types
        end
      end
      return Util.keccak256 encoded.join
    end

    # Recursively ABI-encodes and hashes all data and types.
    #
    # @param primary_type [String, Symbol] the primary type which we want to hash.
    # @param data [Array] the data in the data structure we want to hash.
    # @param types [Array] all existing types in the data structure.
    # @return [String] a Keccak-256 hash of the ABI-encoded data and types.
    def hash_data(primary_type, data, types)
      encoded_data = encode_data primary_type, data, types
      return Util.keccak256 encoded_data
    end

    # Enforces basic properties to be represented in the EIP-712 typed
    # data structure: types, domain, message, etc.
    #
    # @param data [Array] the data in the data structure we want to hash.
    # @return [Array] the data in the data structure we want to hash.
    # @raise [TypedDataError] if the data fails validation.
    def enforce_typed_data(data)
      data = JSON.parse data if Util.hex? data
      raise TypedDataError, "Data is missing, try again with data." if missing? data
      raise TypedDataError, "Data is not a Hash: #{data.class}." unless hash_like? data
      raise TypedDataError, "Data types are missing." if missing? data[:types]
      raise TypedDataError, "Data primaryType is missing." if missing? data[:primaryType]
      raise TypedDataError, "Data domain is missing." if data[:domain].nil?
      raise TypedDataError, "Data message is missing." if missing? data[:message]
      # the types are a Hash before EIP712Domain is looked up in them
      raise TypedDataError, "Data types are not a Hash: #{data[:types].class}." unless hash_like? data[:types]
      raise TypedDataError, "Data EIP712Domain is missing." if data[:types][:EIP712Domain].nil?

      # then the shape of the schema, but not its field values
      raise TypedDataError, "Data primaryType is not a String or Symbol: #{data[:primaryType].class}." unless string_or_symbol? data[:primaryType]
      raise TypedDataError, "Data domain is not a Hash: #{data[:domain].class}." unless hash_like? data[:domain]
      raise TypedDataError, "Data message is not a Hash: #{data[:message].class}." unless hash_like? data[:message]
      data[:types].each_pair { |type, fields| enforce_fields type, fields }
      return data
    end

    # Hashes a typed data structure with Keccak-256 to prepare a signed
    # typed data operation respecting EIP-712.
    #
    # @param data [Array] all the data in the typed data structure.
    # @return [String] a Keccak-256 hash of the EIP-712-encoded typed data.
    def hash(data)
      data = enforce_typed_data data

      # EIP-191 prefix byte
      buffer = Signature::EIP191_PREFIX_BYTE

      # EIP-712 version byte
      buffer += Signature::EIP712_VERSION_BYTE

      # hashed domain data
      buffer += hash_data "EIP712Domain", data[:domain], data[:types]

      # hashed message data
      buffer += hash_data data[:primaryType], data[:message], data[:types]
      return Util.keccak256 buffer
    end

    private

    # Checks the field list of one type definition: each field entry is a
    # Hash with a String or Symbol name and type. The field values are
    # checked when they are encoded.
    def enforce_fields(type, fields)
      raise TypedDataError, "Data type #{type} is not a list of fields: #{fields.class}." unless fields.respond_to? :each and !fields.respond_to? :each_pair
      fields.each do |field|
        raise TypedDataError, "Data type #{type} has a field that is not a Hash: #{field.class}." unless hash_like? field
        raise TypedDataError, "Data type #{type} has a field name that is not a String or Symbol: #{field[:name].class}." unless string_or_symbol? field[:name]
        raise TypedDataError, "Data type #{type} has a field type that is not a String or Symbol: #{field[:type].class}." unless string_or_symbol? field[:type]
      end
    end

    # A value is missing if it is nil, or empty when it answers empty?.
    def missing?(value)
      value.nil? or (value.respond_to? :empty? and value.empty?)
    end

    # Typed data and its Hash members are a Hash or answer each_pair like
    # one, e.g., an OpenStruct; a Struct answers each_pair too, but raises
    # NameError for keys it lacks.
    def hash_like?(value)
      value.respond_to? :each_pair and !value.is_a? Struct
    end

    # Type names and field names are Strings or Symbols, or answer to_sym
    # like them, e.g., a SimpleDelegator of a String.
    def string_or_symbol?(value)
      value.respond_to? :to_sym
    end
  end
end
