#  -*- encoding : ascii-8bit -*-

# Provides the `Eth` module.
module Eth

  # Provides a Ruby implementation of the Ethereum Applicatoin Binary Interface (ABI).
  module Abi

    # Provides commonly used constants, such as zero bytes or zero keys.
    module Constant

      # The empty byte is defined as "".
      BYTE_EMPTY = "".freeze

      # The zero byte is 0x00.
      BYTE_ZERO = "\x00".freeze

      # The byte one is 0x01.
      BYTE_ONE = "\x01".freeze

      # The size of a 32-bit number.
      TT32 = 2 ** 32

      # The size of a 256-bit number.
      TT256 = 2 ** 256

      # The maximum possible value of an UInt256.
      UINT_MAX = 2 ** 256 - 1

      # The minimum possible value of an UInt256.
      UINT_MIN = 0

      # The maximum possible value of an Int256.
      INT_MAX = 2 ** 255 - 1

      # The minimum possible value of an Int256.
      INT_MIN = -2 ** 255

      # A hash containing only zeros.
      HASH_ZERO = ("\x00" * 32).freeze

      # A private key containing only zeros.
      PRIVKEY_ZERO = ("\x00" * 32).freeze

      # A private key containing only zeros (hex).
      PRIVKEY_ZERO_HEX = ('0' * 64).freeze
    end
  end
end
