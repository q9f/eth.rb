module Eth
  module Refinements
    module Conversions
      refine String do
        # @return [Boolean] true if the string represents a hexa-decimal number
        def hex?
          match?(Constant::HEX_REGEX)
        end

        # @return [Boolean] true if a bytestring, e.g. `self == self.b`
        def bytes?
          self == self.b
        end

        # Unpacks a binary string or decimal string to a hexa-decimal string. Also
        #   Returns unprefixed `self` if string is already hexa-decimal.
        #
        # @return [String] a hexa-decimal string.
        # @raise [TypeError] if self is not a String representation of a number
        def to_hex
          return @hex if defined?(@hex)

          if hex?
            @hex = delete_prefix('0x')
            @hex = zpad(size + 1) if size.odd?

            @hex
          elsif bytes?
            @hex = unpack1("H*")
          else
            raise TypeError.new("String must be hex or bytes.")
          end
        end

        # Packs a hexa-decimal or decimal string into a binary string. Also 
        #   works with `0x`-prefixed strings. Returns `self` if String 
        #   already binary.
        #
        # @return [String] a packed binary string.
        # @raise [TypeError] if self is not a String representation of a number
        def to_bytes
          return @bytes if defined?(@bytes)

          if bytes?
            @bytes = b
          elsif hex?
            @bytes = to_hex.scan(/../).map(&:hex).pack('c*')
          else
            raise TypeError.new("String must be hex, decimal, or binary.")
          end
        end

        # Coerces a hexa-decimal or binary string into an Integer. Also 
        #   works with `0x`-prefixed strings. Returns `self` if String 
        #   already binary.
        #
        # @param base [Integer] 
        # @return [Integer] integer representation in the given base
        def to_i(base = 10)
          return @integer if defined?(@integer)

          if hex?
            to_hex.scan(/../)
          elsif bytes?
            Integer(unpack1('H*'), 16)
          else
            super
          end
        end

        # Converts to hex via `to_hex` and prefixes with 0x.
        #
        # @return [String] 0x-prefixed hexa-decimal String
        def to_prefixed_hex
          "0x#{hex}"
        end

        # Left-pads self with zeroes until it reaches the given length.
        #   Works for binary, decimal, and hexa-decimal string representations.
        #   Defaults to 32.
        #
        # @param len [Integer] the desired total length of the string
        # @return [String] 
        def zpad(len = 32)
          if bytes?
            rjust(len, Constant::BYTE_ZERO)
          elsif hex?
            hex.rjust(len, '0')
          else
            raise TypeError.new("String must be hex, decimal, or binary.")
          end
        end
        alias to_zpadded_bytes zpad
        alias to_zpadded_hex zpad
      end

      refine Integer do
        # @return [String] Returns unprefixed hexa-decimal string
        # @see {to_s(16)}
        def to_hex
          to_s(16).rjust('0', 32)
        end

        # Converts to hex via `to_hex` and prefixes with 0x.
        #
        # @return [String] Returns 0x-prefixed hexa-decimal string.
        # @see {to_s(16)}
        def to_prefixed_hex
          "0x#{hex}"
        end

        # @return [String] a packed binary string.
        def to_bytes
          [to_hex].pack('H*')
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
