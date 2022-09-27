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
  module Types
    # Provides a numeric data type with painless conversions
    #   between bytes, hex, and decimal. {Num}'s constructor
    #   should not be given a value directly. Instead, use
    #   one of its subclasses.
    #
    # @see {https://github.com/q9f/secp256k1.cr/blob/master/src/secp256k1/num.cr}
    #
    # @example Num.new
    # @example Hex.new('0xdeadbeef')
    # @example Dec.new(1)
    # @example Bin.new(Eth::Util.keccak256('str'))
    #
    # @raise [ArgumentError] raised if input is a String but
    #   isn't hex or bytes, or if input is an Array but not
    #   a list of ascii-8bit numbers
    # @raise [NotImplementedError] raised if Num is instantiated
    #   with a value directly
    class Num
      # raw input
      attr_reader :input

      # value as bytestring
      attr_reader :bin

      # value in decimal
      attr_reader :dec

      # value in hexa-decimal
      attr_reader :hex

      # Instantiates a Num with {@hex} set to {SecureRandom.hex(16)}
      #   then uses conversion methods to set the bytestring and
      #   {Integer}.
      def initialize(input = nil)
        if input && block_given?
          begin
            @input = input.freeze

            raise ArgumentError, "number cannot be coerced" unless valid?

            yield

            format_hex!
          rescue StandardError => e
            raise ArgumentError, "number cannot be coerced: #{e.message}"
          end
        elsif input.nil?
          randomize!
        else
          raise NotImplementedError, "must use a subclass: Hex, Dec, or Bin"
        end

        freeze!
      end

      # Memoizes and returns 0x-prefixed hex
      #
      # @return [String]
      def to_prefixed_hex
        @prefixed_hex ||= "0x#{hex}".freeze
      end

      # Left-pads self with zeroes until it reaches the given length.
      #   Works for binary, decimal, and hexa-decimal string representations.
      #   Defaults to 32.
      #
      # @param len [Integer] the desired total length of the string
      # @return [String]
      def zpad(expected_length)
        dec.to_s.rjust(expected_length, "0")
      end

      private

      # @return [Boolean] true if the string is either 0x-prefixed or non-prefixed hex
      def hex?
        input.match?(Constant::HEX_REGEX)
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
        !input.b.ascii_only?
      end

      # makes the object immutable
      def freeze!
        @hex.freeze
        @bin.freeze
        @dec.freeze
      end

      # helper for formatting hex
      def format_hex!
        @hex = hex.delete_prefix("0x").tap do |h|
          h.rjust(h.size + 1, "0") if h.size.odd?
        end
      end

      # generate random Num values
      def randomize!
        random_hex = Hex.new((rand * 100).to_i.to_s(16))
        @hex = random_hex.hex
        @bin = random_hex.bin
        @dec = random_hex.dec
      end

      def _bin_to_hex
        bin.unpack1("H*")
      end

      def _hex_to_bin
        hex.scan(/../).map(&:hex).pack("C*").b
      end
    end
  end
end
