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

    # List of available ABI types.
    META_TYPES = [
      "AddressType",
      "ArrayType",
      "BooleanType",
      "BytesType",
      "FixedArrayType",
      "FixedBytesType",
      "IntType",
      "StringType",
      "TupleType",
      "UIntType",
    ]

    # Provides a class to handle and parse common ABI types.
    class MetaType

      # Parses a given type and returns a parsed type object.
      #
      # @param type [Object] a type to parse.
      #
      # @return [MetaType] a parsed type object.
      def self.parse(type)
        # @TODO parse
      end

      # Allows determining if the type is of dynamic size.
      #
      # @return [Boolean] true if type is dynamic in size.
      def dynamic?
        size.nil?
      end

      # Interface to force implementing the size method in child classes.
      #
      # @raise NotImplementedError if it's not implemented.
      def size
        raise NotImplementedError, "The size is not implemented for #{self.class.name}."
      end

      # Interface to force implementing the size method in child classes.
      #
      # @raise [NotImplementedError] if it's not implemented.
      def format
        raise NotImplementedError, "The format is not implemented for #{self.class.name}."
      end
    end
  end
end

require "eth/abi/types/address"
require "eth/abi/types/array"
require "eth/abi/types/boolean"
require "eth/abi/types/bytes"
require "eth/abi/types/fixed_array"
require "eth/abi/types/fixed_bytes"
require "eth/abi/types/int"
require "eth/abi/types/string"
require "eth/abi/types/tuple"
require "eth/abi/types/uint"
