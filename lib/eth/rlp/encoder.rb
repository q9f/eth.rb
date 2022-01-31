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

    # Provides an RLP-encoder.
    module Encoder
      extend self

      # Encodes a Ruby object in RLP format.
      #
      # @param obj [Object] a Ruby object.
      # @return [String] the RLP encoded item.
      # @raise [Eth::Rlp::EncodingError] in the rather unlikely case that the item
      #     is too big to encode (will not happen).
      # @raise [Eth::Rlp::SerializationError] if the serialization fails.
      def perform(obj)
        item = Sedes.infer(obj).serialize(obj)
        result = encode_raw item
      end

      private

      # Encodes the raw item.
      def encode_raw(item)
        return item if item.instance_of? Rlp::Data
        return encode_primitive item if Util.is_primitive? item
        return encode_list item if Util.is_list? item
        raise EncodingError "Cannot encode object of type #{item.class.name}"
      end

      # Encodes a single primitive.
      def encode_primitive(item)
        return Util.str_to_bytes item if item.size == 1 && item.ord < Constant::PRIMITIVE_PREFIX_OFFSET
        payload = Util.str_to_bytes item
        prefix = length_prefix payload.size, Constant::PRIMITIVE_PREFIX_OFFSET
        "#{prefix}#{payload}"
      end

      # Encodes a single list.
      def encode_list(list)
        payload = list.map { |item| encode_raw item }.join
        prefix = length_prefix payload.size, Constant::LIST_PREFIX_OFFSET
        "#{prefix}#{payload}"
      end

      # Determines a length prefix.
      def length_prefix(length, offset)
        if length < Constant::SHORT_LENGTH_LIMIT
          (offset + length).chr
        elsif length < Constant::LONG_LENGTH_LIMIT
          length_string = Util.int_to_big_endian length
          length_len = (offset + Constant::SHORT_LENGTH_LIMIT - 1 + length_string.size).chr
          "#{length_len}#{length_string}"
        else
          raise EncodingError, "Length greater than 256**8: #{length}"
        end
      end
    end
  end
end
