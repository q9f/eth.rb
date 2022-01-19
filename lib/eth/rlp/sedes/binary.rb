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
      class Binary
        INFINITY = (1.0 / 0.0).freeze

        class << self
          def fixed_length(l, allow_empty: false)
            new(min_length: l, max_length: l, allow_empty: allow_empty)
          end

          def valid_type?(obj)
            obj.instance_of?(String)
          end
        end

        def initialize(min_length: 0, max_length: INFINITY, allow_empty: false)
          @min_length = min_length
          @max_length = max_length
          @allow_empty = allow_empty
        end

        def serialize(obj)
          raise Error::SerializationError.new("Object is not a serializable (#{obj.class})", obj) unless self.class.valid_type?(obj)
          serial = Util.str_to_bytes obj
          raise Error::SerializationError.new("Object has invalid length", serial) unless valid_length?(serial.size)
          serial
        end

        def deserialize(serial)
          raise Error::DeserializationError.new("Objects of type #{serial.class} cannot be deserialized", serial) unless primitive?(serial)
          raise Error::DeserializationError.new("#{serial.class} has invalid length", serial) unless valid_length?(serial.size)
          serial
        end

        private

        def valid_length?(len)
          (@min_length <= len && len <= @max_length) ||
            (@allow_empty && len == 0)
        end
      end
    end
  end
end
