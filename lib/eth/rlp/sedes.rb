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

# Provides the {Eth} module.
module Eth

  # Provides an recursive-length prefix (RLP) encoder and decoder.
  module Rlp

    # Provides serializable and deserializable types (SeDes).
    module Sedes

      # Provides a singleton {Eth::Rlp::Sedes} class to infer objects and types.
      class << self

        # Tries to find a sedes objects suitable for a given Ruby object.
        #
        # The sedes objects considered are `obj`'s class, {big_endian_int} and
        # {binary}. If `obj` is a list, an {Eth::Rlp::Sedes::List} will be
        # constructed recursively.
        #
        # @param obj [Object] the Ruby object for which to find a sedes object.
        # @raise [TypeError] if no appropriate sedes could be found.
        def infer(obj)
          return obj.class if is_sedes? obj.class
          return big_endian_int if obj.is_a?(Integer) && obj >= 0
          return binary if Binary.valid_type? obj
          return List.new(elements: obj.map { |item| infer item }) if Util.is_list? obj
          raise TypeError, "Did not find sedes handling type #{obj.class.name}"
        end

        # Determines if an object is a sedes object.
        #
        # @param obj [Object] the object to check.
        # @return [Boolean] true if it's serializable and deserializable.
        def is_sedes?(obj)
          obj.respond_to?(:serialize) && obj.respond_to?(:deserialize)
        end

        # A utility to use a big-endian, unsigned integer sedes type with
        # unspecified length.
        #
        # @return [Eth::Rlp::Sedes::BigEndianInt] a big-endian, unsigned integer sedes.
        def big_endian_int
          @big_endian_int ||= BigEndianInt.new
        end

        # A utility to use a binary sedes type.
        #
        # @return [Eth::Rlp::Sedes::Binary] a binary sedes.
        def binary
          @binary ||= Binary.new
        end
      end
    end
  end
end
