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

    # Provides a class to handle and parse fixed array types.
    class FixedArrayType < MetaType

      # The used sub-type of the array type.
      attr_reader :sub_type

      # The dimension of the fixed array type.
      attr_reader :dimension

      # Creates an array type of the given sub-type and fixed dimension.
      #
      # @param sub_type [MetaType] a sub-type for the array type.
      # @param dimension [Integer] the fixed dimension of the array type.
      # @raise [ArgumentError] if an invalid sub-type is provided.
      def initialize(sub_type, dimension)
        raise ArgumentError, "Invalid sub-type provided: #{sub_type}" unless META_TYPES.include? sub_type.class.name.split(":").last
        @sub_type = sub_type
        @dimension = dimension
      end

      # Gets the full size of the fixed array type.
      #
      # @return nil if subtype is dynamic.
      # @return [Integer] size of the fixed array if sub-types are not dynamic.
      def size
        return nil if @sub_type.dynamic?
        return @dimension * @sub_type.size
      end

      # Gets the string representation of a fixed array type.
      #
      # @return [String] containing the subtype, size, and dimension.
      def format
        "#{@sub_type.format}[#{@dimension}]".freeze
      end

      # Allows to compare two array types.
      #
      # @return [Boolean] true if types are of same class.
      def ==(another_type)
        another_type.kind_of? FixedArrayType and
        @sub_type == another_type.sub_type and
        @dimension == another_type.dimension
      end
    end
  end
end
