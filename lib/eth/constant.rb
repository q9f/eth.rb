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

#  -*- encoding : ascii-8bit -*-

# Provides the {Eth} module.
module Eth

  # Provides commonly used constants, such as zero bytes or zero keys.
  module Constant

    # The empty byte is defined as "".
    BYTE_EMPTY = "".freeze

    # The zero byte is 0x00.
    BYTE_ZERO = "\x00".freeze

    # The byte one is 0x01.
    BYTE_ONE = "\x01".freeze

    # The size of a 32-bit number.
    TT32 = (2 ** 32).freeze

    # The size of a 256-bit number.
    TT256 = (2 ** 256).freeze

    # The maximum possible value of an UInt256.
    UINT_MAX = (2 ** 256 - 1).freeze

    # The minimum possible value of an UInt256.
    UINT_MIN = 0.freeze

    # The maximum possible value of an Int256.
    INT_MAX = (2 ** 255 - 1).freeze

    # The minimum possible value of an Int256.
    INT_MIN = (-2 ** 255).freeze

    # A hash containing only zeros.
    HASH_ZERO = ("\x00" * 32).freeze

    # The RLP short length limit.
    SHORT_LENGTH_LIMIT = 56.freeze

    # The RLP long length limit.
    LONG_LENGTH_LIMIT = (256 ** 8).freeze

    # The RLP primitive type offset.
    PRIMITIVE_PREFIX_OFFSET = 0x80.freeze

    # The RLP array type offset.
    LIST_PREFIX_OFFSET = 0xc0.freeze

    # The binary encoding is ASCII (8-bit).
    BINARY_ENCODING = "ASCII-8BIT".freeze

    # Infinity as constant for convenience.
    INFINITY = (1.0 / 0.0).freeze
  end
end
