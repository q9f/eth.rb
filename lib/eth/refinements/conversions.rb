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

  # Provides the {Refinements} module.
  module Refinements

    # Provides the {Conversions} module.
    #
    # This is essentially a lexically-scoped monkeypatch to add conversion methods
    # to {String} and {Integer} objects without dirtying up the entire codebase.
    #
    # If you want to add `"0xdeadbeef".to_bytes` to your class, you just add
    # `using Refinements::Conversions`. 
    module Conversions
      refine String do

        # @return [Boolean] true if the string is either 0x-prefixed or non-prefixed hex
        def hex?
          match?(Constant::HEX_REGEX)
        end

        # @return [Boolean] true if a bytestring: meaning that its encoding is 
        #   {Encoding::BINARY} but contains non-ascii chars
        # @example
        #   SecureRandom.random_bytes.b.ascii_only?
        #     # => false
        # @example
        #   Digest::Keccak(256).digest('eh').b.ascii_only?
        #     # => false
        def bytes?
          !b.ascii_only?
        end

        # When self is <i>any</i> hex-formatted string, this method standardizes
        #   by removing the 0x prefix and zpadding once if the string
        #   contains an odd number of digits.
        #   
        # Else, when self is a bytestring, this method calls the corresponding
        #   standardized {to_bytes} method and then unpacks as hex, and calls
        #   itself to ensure it's in the standardized format mentioned above.
        #
        # @return [String] a non-0x-prefixed even digit hexa-decimal string.
        # @raise [TypeError] when self is not a hex or bytestring
        def to_hex
          if hex?
            _hex = delete_prefix('0x')

            return _hex if _hex.size.even?
            
            _hex.rjust(_hex.size + 1, '0')
          elsif bytes?
            to_bytes.unpack1("H*").to_hex
          else
            raise TypeError.new("String must be hex or bytestring.")
          end
        end

        # Similar to {to_hex} but inverted
        # @see {to_hex}
        #
        # When self is <i>any</i> hex-formatted string, an array of hex bytes
        #   is mapped to uint8 and packed to a bytestring, then calls itself.
        #   
        # Else, when self is a bytestring, this method calls {b} to ensure
        #   proper encoding.
        #
        # @return [String] bytestring with {Encoding::BINARY}
        # @raise [TypeError] when self is not a hex or bytestring
        def to_bytes
          if hex?
            to_hex.scan(/../).map(&:hex).pack('C*').to_bytes
          elsif bytes?
            b
          else
            raise TypeError.new("String must be hex or bytestring.")
          end
        end

        # Makes it a little simpler to coerce a hexa-decimal or bytestring
        #   into an Integer.
        #
        # @param base [Integer] the base of the String that is being coerced
        # @return [Integer] integer representation in the given base
        def to_i(base = nil)
          return super if base

          if hex?
            to_hex.to_i(16)
          elsif bytes?
            to_bytes.to_i(2)
          else
            super
          end
        end

        # Left-pads self with zeroes until it reaches the given length.
        #   Works for binary, decimal, and hexa-decimal string representations.
        #   Defaults to 32.
        #
        # @param len [Integer] the desired total length of the string
        # @return [String] 
        def zpad(len = 32)
          if hex?
            rjust(len, '0')
          elsif bytes?
            rjust(len, Constant::BYTE_ZERO)
          else
            raise TypeError.new("String must be hex or bytestring.")
          end
        end
        alias to_zpadded_bytes zpad
        alias to_zpadded_hex zpad
      end

      refine Integer do
        # @return [String] Returns unprefixed hexa-decimal string
        # @see {to_s(16)}
        def to_hex
          to_s(16).to_hex
        end

        # @return [String] a packed binary string.
        def to_bytes
          [to_hex].pack('H*').to_bytes
        end

        # Left-pads self with zeroes until it reaches the given length.
        #   Works for binary, decimal, and hexa-decimal string representations.
        #   Defaults to 32.
        #
        # @param len [Integer] the desired total length of the string
        # @return [String] bytestring left-padded with zeroes
        def zpad(len = 32)
          to_bytes.zpad(len / 2)
        end
        alias to_zpadded_bytes zpad
        alias to_zpadded_hex zpad
      end
    end
  end
end
