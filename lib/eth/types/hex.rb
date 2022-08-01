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

  # Provides the {Eth} module.
  module Types
    # Subclass of {Num} that represents a hex string
    #
    # @see {Num}
    #
    # @example Instantiate a Hex object
    #   Hex('0xdeadbeef')
    #     => #<Eth::Types::Hex:0x00007f8dcb102330
    #       @input="0xdeadbeef",
    #       @hex="deadbeef",
    #       @bin="\xDE\xAD\xBE\xEF",
    #       @dec=3735928559>
    class Hex < Num
      def initialize(hex)
        super(hex) do
          to_hex
          to_bin
          to_dec
        end
      end

      def valid?
        hex?
      end

      def to_hex
        @hex ||= input.to_s
        format_hex!
      end

      def to_bin
        @bin ||= _hex_to_bin
      end

      def to_dec
        @dec ||= hex.to_i(16)
      end
    end
  end
end
