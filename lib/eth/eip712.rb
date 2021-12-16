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

require 'rbsecp256k1'

# Provides the `Eth` module.
module Eth

  # Defines handy tools for encoding typed structured data as per EIP-712.
  module Eip712
    extend self

    def type_dependencies primary_type, types, result = []
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

    def encode_type primary_type, types

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
        result += types[type.to_sym].map{|t| "#{t[:type]} #{t[:name]}"}.join(',')
        result += ")"
      end

      return result
    end

    def hash_type primary_type, types
      encoded_type = encode_type primary_type, types
      hash = Util.keccak256 encoded_type
    end
  end
end
