# Copyright (c) 2016-2023 The Ruby-Eth Contributors
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

# Provides the {Eth} module.
module Eth

  # The {Eth::Address} class to handle checksummed Ethereum addresses.
  class Address

    # Provides a special checksum error if EIP-55 is violated.
    class CheckSumError < StandardError; end

    # The prefixed and checksummed Ethereum address.
    attr_reader :address

    # Constructor of the {Eth::Address} class. Creates a new hex
    # prefixed address.
    #
    # @param address [String] hex string representing an ethereum address.
    def initialize(address)
      unless Util.hex? address
        raise CheckSumError, "Unknown address type #{address}!"
      end
      @address = Util.prefix_hex address
      unless self.valid?
        raise CheckSumError, "Invalid address provided #{address}"
      end
    end

    # Checks that the address is valid.
    #
    # @return [Boolean] true if valid address.
    def valid?
      if !matches_any_format?
        false
      elsif not_checksummed?
        true
      else
        checksum_matches?
      end
    end

    # Generate a checksummed address.
    #
    # @return [String] prefixed hexstring representing an checksummed address.
    def checksummed
      raise CheckSumError, "Invalid address: #{address}" unless matches_any_format?

      cased = unprefixed.chars.zip(checksum.chars).map do |char, check|
        check.match(/[0-7]/) ? char.downcase : char.upcase
      end

      Util.prefix_hex cased.join
    end

    alias :to_s :checksummed

    private

    # Checks whether the address checksum matches.
    def checksum_matches?
      address == checksummed
    end

    # Checks whether the address is not checksummed.
    def not_checksummed?
      all_uppercase? || all_lowercase?
    end

    # Checks whether the address is all upper-case.
    def all_uppercase?
      address.match /(?:0[xX])[A-F0-9]{40}/
    end

    # Checks whether the address is all lower-case.
    def all_lowercase?
      address.match /(?:0[xX])[a-f0-9]{40}/
    end

    # Checks whether the address matches any known format.
    def matches_any_format?
      address.match /\A(?:0[xX])[a-fA-F0-9]{40}\z/
    end

    # Computes the checksum of the address.
    def checksum
      Util.bin_to_hex Util.keccak256 unprefixed.downcase
    end

    # Removes the hex prefix.
    def unprefixed
      Util.remove_hex_prefix address
    end
  end
end
