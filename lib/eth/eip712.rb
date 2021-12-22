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

# Provides the `Eth` module.
module Eth

  # Defines handy tools for encoding typed structured data as per EIP-712.
  module Eip712
    extend self

    class TypedDataError < StandardError; end

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
        raise ArgumentError, "Non-primary type found: #{type}!" if types[type.to_sym].nil?

        result += "#{type}("
        result += types[type.to_sym].map { |t| "#{t[:type]} #{t[:name]}" }.join(",")
        result += ")"
      end

      return result
    end

    def hash_type(primary_type, types)
      encoded_type = encode_type primary_type, types
      return Util.keccak256 encoded_type
    end

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

    def hash_data(primary_type, data, types)
      encoded_data = encode_data primary_type, data, types
      return Util.keccak256 encoded_data
    end

    def enforce_typed_data_v4(data)
      data = JSON.parse data if Util.is_hex? data
      raise TypedDataError, "Data is missing, try again with data." if data.nil? or data.empty?
      raise TypedDataError, "Data types are missing." if data[:types].nil? or data[:types].empty?
      raise TypedDataError, "Data primaryType is missing." if data[:primaryType].nil? or data[:primaryType].empty?
      raise TypedDataError, "Data domain is missing." if data[:domain].nil?
      raise TypedDataError, "Data message is missing." if data[:message].nil? or data[:message].empty?
      raise TypedDataError, "Data EIP712Domain is missing." if data[:types][:EIP712Domain].nil?
      return data
    end

    def hash(data)
      data = enforce_typed_data_v4 data

      # EIP-191 prefix byte 0x19
      buffer = "\x19"

      # EIP-712 version byte 0x01
      buffer += "\x01"

      # hashed domain data
      buffer += hash_data "EIP712Domain", data[:domain], data[:types]

      # hashed message data
      buffer += hash_data data[:primaryType], data[:message], data[:types]
      return Util.keccak256 buffer
    end
  end
end
