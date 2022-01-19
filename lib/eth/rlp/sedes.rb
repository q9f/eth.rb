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

require "eth/rlp/sedes/big_endian_int"
require "eth/rlp/sedes/binary"
require "eth/rlp/sedes/list"

# Provides the `Eth` module.
module Eth

  # Provides an recursive-length prefix (RLP) encoder and decoder.
  module Rlp
    module Sedes
      class << self
        def infer(obj)
          return obj.class if is_sedes? obj.class
          return big_endian_int if obj.is_a?(Integer) && obj >= 0
          return binary if Binary.valid_type? obj
          return List.new(elements: obj.map { |item| infer item }) if Util.is_list? obj
          raise TypeError, "Did not find sedes handling type #{obj.class.name}"
        end

        def is_sedes?(obj)
          obj.respond_to?(:serialize) && obj.respond_to?(:deserialize)
        end

        def big_endian_int
          @big_endian_int ||= BigEndianInt.new
        end

        def binary
          @binary ||= Binary.new
        end
      end
    end
  end
end
