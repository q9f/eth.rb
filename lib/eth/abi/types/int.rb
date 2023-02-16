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

    # Provides a class to handle and parse integer types.
    class IntType < MetaType

      # Size of the integer type in bits.
      attr_reader :bits

      # Initializes an integer type for a given bit-size.
      #
      # @param bits [Integer] the bit-size of the fixed type (8, 16, .. 256).
      # @raise [ArgumentError] if an invalid type bit-size is provided.
      def initialize(bits = 256)
        raise ArgumentError, "Invalid fixed type size provided: int#{bits}" unless [8, 16, 32, 64, 128, 256].include? bits
        @bits = bits
      end

      # Gets the static byte-size of an integer type.
      #
      # @return [Integer] 32 (bytes).
      def size
        32.freeze
      end

      # Gets the string representation of an integer type.
      #
      # @return [String] `address`.
      def format
        "int#{@bits}".freeze
      end

      # Allows to compare two integer types.
      #
      # @return [Boolean] true if types are of same class and size.
      def ==(another_type)
        another_type.kind_of? IntType and @bits === another_type.bits
      end
    end
  end
end
