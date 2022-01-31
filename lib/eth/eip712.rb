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
          dependency = type_dependencies t[:type], types, result
        end
        return result
      end
    end

    # Encode types as an EIP-712 confrom string, e.g.,
    # `MyType(string attribute)`.
    #
    # @param primary_type [String] the type which we want to encode.
    # @param types [Array] all existing types in the data structure.
    # @return [String] an EIP-712 encoded type-string.
    # @raise [TypedDataError] if non-primary type found.
    def encode_type(primary_type, types)

      # get all used types
      all_dependencies = type_dependencies primary_type, types

      # remove primary types and sort the rest alphabetically
      filtered_dependencies = all_dependencies.delete_if { |type| type.to_s == primary_type }
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
    # @param primary_type [String] the type which we want to hash.
    # @param types [Array] all existing types in the data structure.
    # @return [String] a Keccak-256 hash of an EIP-712 encoded type-string.
    def hash_type(primary_type, types)
      encoded_type = encode_type primary_type, types
      return Util.keccak256 encoded_type
    end

    # Recursively ABI-encodes all data and types according to EIP-712.
    #
    # @param primary_type [String] the primary type which we want to encode.
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
        raise NotImplementedError, "Arrays currently unimplemented for EIP-712." if type.end_with? "]"
        if type == "string" or type == "bytes"
          encoded_types.push "bytes32"
          encoded_values.push Util.keccak256 value
        elsif !types[type.to_sym].nil?
          encoded_types.push "bytes32"
          value = encode_data type, value, types
          encoded_values.push Util.keccak256 value
        else
          encoded_types.push type
          encoded_values.push value
        end
      end

      # all data is abi-encoded
      return Abi.encode encoded_types, encoded_values
    end

    # Recursively ABI-encodes and hashes all data and types.
    #
    # @param primary_type [String] the primary type which we want to hash.
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
      data = JSON.parse data if Util.is_hex? data
      raise TypedDataError, "Data is missing, try again with data." if data.nil? or data.empty?
      raise TypedDataError, "Data types are missing." if data[:types].nil? or data[:types].empty?
      raise TypedDataError, "Data primaryType is missing." if data[:primaryType].nil? or data[:primaryType].empty?
      raise TypedDataError, "Data domain is missing." if data[:domain].nil?
      raise TypedDataError, "Data message is missing." if data[:message].nil? or data[:message].empty?
      raise TypedDataError, "Data EIP712Domain is missing." if data[:types][:EIP712Domain].nil?
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
  end
end
