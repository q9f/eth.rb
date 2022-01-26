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
        class << self
          def fixed_length(l, allow_empty: false)
            new(min_length: l, max_length: l, allow_empty: allow_empty)
          end

          def valid_type?(obj)
            obj.instance_of?(String)
          end
        end

        def initialize(min_length: 0, max_length: Constant::INFINITY, allow_empty: false)
          @min_length = min_length
          @max_length = max_length
          @allow_empty = allow_empty
        end

        def serialize(obj)
          raise SerializationError, "Object is not a serializable (#{obj.class})" unless self.class.valid_type?(obj)
          serial = Util.str_to_bytes obj
          raise SerializationError, "Object has invalid length" unless valid_length?(serial.size)
          serial
        end

        def deserialize(serial)
          raise DeserializationError, "Objects of type #{serial.class} cannot be deserialized" unless Util.is_primitive?(serial)
          raise DeserializationError, "#{serial.class} has invalid length" unless valid_length?(serial.size)
          serial
        end

        private

        def valid_length?(len)
          (@min_length <= len && len <= @max_length) || (@allow_empty && len == 0)
        end
      end
    end
  end
end
