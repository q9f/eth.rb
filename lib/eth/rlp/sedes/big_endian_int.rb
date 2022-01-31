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

      # A serializable, big-endian, unsigned integer type.
      class BigEndianInt

        # Create a serializable, big-endian, unsigned integer.
        #
        # @param size [Integer] the size of the big endian.
        def initialize(size = nil)
          @size = size
        end

        # Serialize a big-endian integer.
        #
        # @param obj [Integer] the integer to be serialized.
        # @return [String] a serialized big-endian integer.
        # @raise [SerializationError] if provided object is not an integer.
        # @raise [SerializationError] if provided integer is negative.
        # @raise [SerializationError] if provided integer is too big for @size.
        def serialize(obj)
          raise SerializationError, "Can only serialize integers" unless obj.is_a?(Integer)
          raise SerializationError, "Cannot serialize negative integers" if obj < 0
          raise SerializationError, "Integer too large (does not fit in #{@size} bytes)" if @size && obj >= 256 ** @size
          s = obj == 0 ? Constant::BYTE_EMPTY : Util.int_to_big_endian(obj)
          @size ? "#{Constant::BYTE_ZERO * [0, @size - s.size].max}#{s}" : s
        end

        # Deserializes an unsigned integer.
        #
        # @param serial [String] the serialized integer.
        # @return [Integer] a number.
        # @raise [DeserializationError] if provided serial is of wrong size.
        # @raise [DeserializationError] if provided serial is not of minimal length.
        def deserialize(serial)
          raise DeserializationError, "Invalid serialization (wrong size)" if @size && serial.size != @size
          raise DeserializationError, "Invalid serialization (not minimal length)" if !@size && serial.size > 0 && serial[0] == Constant::BYTE_ZERO
          serial = serial || Constant::BYTE_ZERO
          Util.big_endian_to_int(serial)
        end
      end
    end
  end
end
