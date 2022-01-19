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

# Provides the `Eth` module.
module Eth

  # Provides an recursive-length prefix (RLP) encoder and decoder.
  module Rlp
    module Sedes
      class BigEndianInt
        def initialize(size = nil)
          @size = size
        end

        def serialize(obj)
          raise Error::SerializationError.new("Can only serialize integers", obj) unless obj.is_a?(Integer)
          raise Error::SerializationError.new("Cannot serialize negative integers", obj) if obj < 0
          if @size && obj >= 256 ** @size
            msg = "Integer too large (does not fit in #{@size} bytes)"
            raise Error::SerializationError.new(msg, obj)
          end
          s = obj == 0 ? Constant::BYTE_EMPTY : Util.int_to_big_endian(obj)
          @size ? "#{Constant::BYTE_ZERO * [0, @size - s.size].max}#{s}" : s
        end

        def deserialize(serial)
          raise Error::DeserializationError.new("Invalid serialization (wrong size)", serial) if @size && serial.size != @size
          raise Error::DeserializationError.new("Invalid serialization (not minimal length)", serial) if !@size && serial.size > 0 && serial[0] == Constant::BYTE_ZERO
          serial = serial || Constant::BYTE_ZERO
          Util.big_endian_to_int(serial)
        end
      end
    end
  end
end
