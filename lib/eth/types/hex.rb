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
    # Subclass of {Num} that represents a hex sting
    #
    # @see {Num}
    #
    # @example Convert a bytestring to hex
    #   Hex(Keccak256.digest('eh'))
    #     =>  
    class Hex < Num

      def initialize(input)
        @input = input

        @hex = input.delete_prefix("0x")
        @hex = hex.rjust(hex.size + 1, "0") if hex.size.odd?
        @bin = Bin(hex.scan(/../).map(&:hex).pack("C*"))
        @dec = Dec(hex.input.to_i(16))
      end
    end
  end
end
