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

    # Provides a class to handle and parse address types.
    class AddressType < MetaType

      # Gets the static byte-size of an address type.
      #
      # @return [Integer] 32 (bytes).
      def size
        32.freeze
      end

      # Gets the string representation of an address type.
      #
      # @return [String] `address`.
      def format
        "address".freeze
      end

      # Allows to compare two address types.
      #
      # @return [Boolean] true if types are of same class.
      def ==(another_type)
        another_type.kind_of? AddressType
      end
    end
  end
end
