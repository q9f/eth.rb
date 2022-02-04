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

    # Provides an RLP-decoder.
    module Decoder
      extend self

      # Decodes an RLP-encoded object.
      #
      # @param rlp [String] an RLP-encoded object.
      # @return [Object] the decoded and maybe deserialized object.
      # @raise [Eth::Rlp::DecodingError] if the input string does not end after
      #     the root item.
      def perform(rlp)
        rlp = Util.hex_to_bin rlp if Util.is_hex? rlp
        rlp = Util.str_to_bytes rlp
        begin
          item, next_start = consume_item rlp, 0
        rescue Exception => e
          raise DecodingError, "Cannot decode rlp string: #{e}"
        end
        raise DecodingError, "RLP string ends with #{rlp.size - next_start} superfluous bytes" if next_start != rlp.size
        return item
      end

      private

      # Consume an RLP-encoded item from the given start.
      def consume_item(rlp, start)
        t, l, s = consume_length_prefix rlp, start
        consume_payload rlp, s, t, l
      end

      # Consume an RLP length prefix at the given position.
      def consume_length_prefix(rlp, start)
        b0 = rlp[start].ord
        if b0 < Constant::PRIMITIVE_PREFIX_OFFSET

          # single byte
          [:str, 1, start]
        elsif b0 < Constant::PRIMITIVE_PREFIX_OFFSET + Constant::SHORT_LENGTH_LIMIT
          raise DecodingError, "Encoded as short string although single byte was possible" if (b0 - Constant::PRIMITIVE_PREFIX_OFFSET == 1) && rlp[start + 1].ord < Constant::PRIMITIVE_PREFIX_OFFSET

          # short string
          [:str, b0 - Constant::PRIMITIVE_PREFIX_OFFSET, start + 1]
        elsif b0 < Constant::LIST_PREFIX_OFFSET
          enforce_no_zero_bytes rlp, start

          # long string
          ll = b0 - Constant::PRIMITIVE_PREFIX_OFFSET - Constant::SHORT_LENGTH_LIMIT + 1
          l = Util.big_endian_to_int rlp[(start + 1)...(start + 1 + ll)]
          raise DecodingError, "Long string prefix used for short string" if l < Constant::SHORT_LENGTH_LIMIT
          [:str, l, start + 1 + ll]
        elsif b0 < Constant::LIST_PREFIX_OFFSET + Constant::SHORT_LENGTH_LIMIT

          # short list
          [:list, b0 - Constant::LIST_PREFIX_OFFSET, start + 1]
        else
          enforce_no_zero_bytes rlp, start

          # long list
          ll = b0 - Constant::LIST_PREFIX_OFFSET - Constant::SHORT_LENGTH_LIMIT + 1
          l = Util.big_endian_to_int rlp[(start + 1)...(start + 1 + ll)]
          raise DecodingError, "Long list prefix used for short list" if l < Constant::SHORT_LENGTH_LIMIT
          [:list, l, start + 1 + ll]
        end
      end

      # Enforce RLP slices to not start with empty bytes.
      def enforce_no_zero_bytes(rlp, start)
        raise DecodingError, "Length starts with zero bytes" if rlp.slice(start + 1) == Constant::BYTE_ZERO
      end

      # Consume an RLP payload at the given position of given type and size.
      def consume_payload(rlp, start, type, length)
        case type
        when :str
          [rlp[start...(start + length)], start + length]
        when :list
          items = []
          next_item_start = start
          payload_end = next_item_start + length
          while next_item_start < payload_end
            item, next_item_start = consume_item rlp, next_item_start
            items.push item
          end
          raise DecodingError, "List length prefix announced a too small length" if next_item_start > payload_end
          [items, next_item_start]
        else
          raise TypeError, "Type must be either :str or :list"
        end
      end
    end
  end
end
