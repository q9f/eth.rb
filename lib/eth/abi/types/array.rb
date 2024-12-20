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

    # Provides a class to handle and parse array types.
    class ArrayType < MetaType

      # The used sub-type of the array type.
      attr_reader :sub_type

      # Creates a dynamic array type of the given sub-type.
      #
      # @param sub_type [MetaType] a sub-type for the array type.
      # @raise [ArgumentError] if an invalid sub-type is provided.
      def initialize(sub_type)
        raise ArgumentError, "Invalid sub-type provided: #{sub_type}" unless sub_type.kind_of? MetaType
        @sub_type = sub_type
      end

      # Gets nothing because array types are dynamic in size.
      #
      # @return nil
      def size
        nil
      end

      # Gets the string representation of an array type.
      #
      # @return [String] containing the subtype and size.
      def format
        "#{@sub_type.format}[]".freeze
      end

      # Allows to compare two array types.
      #
      # @return [Boolean] true if types are of same class.
      def ==(another_type)
        another_type.kind_of? ArrayType and @sub_type == another_type.sub_type
      end
    end
  end
end
