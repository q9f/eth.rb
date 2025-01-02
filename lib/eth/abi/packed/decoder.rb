# Copyright (c) 2016-2025 The Ruby-Eth Contributors
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

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
  module Abi

    # Encapsulates the module for non-standard packed encoding used in Solidity.
    module Packed

      # Provides a utility module to assist decoding ABIs.
      module Decoder

        # Since the encoding is ambiguous, there is no decoding function.
        #
        # @param types [Array] the ABI to be decoded.
        # @param data [String] ABI data to be decoded.
        # @raise [DecodingError] if you try to decode packed ABI data.
        # def decode_packed(types, data)
        #   raise DecodingError, "Since the encoding is ambiguous, there is no decoding function."
        # end
      end
    end
  end
end
