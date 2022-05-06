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

# -*- encoding : ascii-8bit -*-

# Provides the {Eth} module.
module Eth

  # Provides an recursive-length prefix (RLP) encoder and decoder.
  module Rlp

    # Provides serializable and deserializable types (SeDes).
    module Sedes

      # A sedes type for binary values.
      class Binary

        # A singleton class for binary values of fixed length.
        class << self

          # Create a serializable binary of fixed size.
          #
          # @param l [Integer] the fixed size of the binary.
          # @param allow_empty [Boolean] indicator wether empty binaries should be allowed.
          # @return [Eth::Rlp::Sedes::Binary] a serializable binary of fixed size.
          def fixed_length(l, allow_empty: false)
            new(min_length: l, max_length: l, allow_empty: allow_empty)
          end

          # Checks wether the given object is of a valid binary type.
          #
          # @param obj [Object] the supposed binary item to check.
          # @return [Boolean] true if valid.
          def valid_type?(obj)
            obj.instance_of? String
          end
        end

        # Create a serializable binary of variable size.
        #
        # @param min_length [Integer] the minimum size of the binary.
        # @param max_length [Integer] the maximum size of the binary.
        # @param allow_empty [Boolean] indicator wether empty binaries should be allowed.
        def initialize(min_length: 0, max_length: Constant::INFINITY, allow_empty: false)
          @min_length = min_length
          @max_length = max_length
          @allow_empty = allow_empty
        end

        # Serializes a binary.
        #
        # @param obj [String] the binary to serialize.
        # @return [Object] a serialized binary.
        # @raise [SerializationError] if provided object is of invalid type.
        # @raise [SerializationError] if provided binary is of invalid length.
        def serialize(obj)
          raise SerializationError, "Object is not a serializable (#{obj.class})" unless self.class.valid_type? obj
          serial = Util.str_to_bytes obj
          raise SerializationError, "Object has invalid length" unless valid_length? serial.size
          serial
        end

        # Deserializes a binary.
        #
        # @param serial [Object] the serialized binary.
        # @return [String] a deserialized binary.
        # @raise [DeserializationError] if provided serial is of wrong type.
        # @raise [DeserializationError] if provided serial is of wrong length.
        def deserialize(serial)
          raise DeserializationError, "Objects of type #{serial.class} cannot be deserialized" unless Util.is_primitive? serial
          raise DeserializationError, "#{serial.class} has invalid length" unless valid_length? serial.size
          serial
        end

        # Checks wether the given length fits the defined size boundaries of the
        # binary type.
        #
        # @param length [Integer] the supposed length of the binary item.
        # @return [Boolean] true if valid.
        def valid_length?(length)
          (@min_length <= length && length <= @max_length) || (@allow_empty && length == 0)
        end
      end
    end
  end
end
