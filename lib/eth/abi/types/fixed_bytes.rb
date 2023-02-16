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

    # Provides a class to handle and parse fixed bytes types.
    class FixedBytesType < MetaType

      # Size of the fixed bytes type in bytes.
      attr_reader :length

      # Initializes a fixed bytes type for a given byte-size.
      #
      # @param length [Integer] the byte-size of the fixed type (1, 2, .. 32).
      # @raise [ArgumentError] if an invalid type byte-size is provided.
      def initialize(length = 32)
        raise ArgumentError, "Invalid fixed type size provided: bytes#{length}" unless [1, 2, 4, 8, 16, 32].include? length
        @length = length
      end

      # Gets the static byte-size of a fixed bytes type.
      #
      # @return [Integer] 32 (bytes).
      def size
        32.freeze
      end

      # Gets the string representation of a fixed bytes type.
      #
      # @return [String] `address`.
      def format
        "bytes#{@length}".freeze
      end

      # Allows to compare two fixed bytes types.
      #
      # @return [Boolean] true if types are of same class and length.
      def ==(another_type)
        another_type.kind_of? FixedBytesType and @length === another_type.length
      end
    end
  end
end
