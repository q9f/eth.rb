# Copyright 2021-2022 Afri Schoedon
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

require 'rbsecp256k1'
require 'securerandom'

module Eth

  # The `Eth::Key` class to handle Secp256k1 private/public key-pairs.
  class Key

    # The `Secp256k1::PrivateKey` of the `Eth::Key` pair.
    attr_reader :private_key

    # The `Secp256k1::PublicKey` of the `Eth::Key` pair.
    attr_reader :public_key

    # Constructor of the `Eth::Key` class. Creates a new random key-pair
    # if no `priv` key is provided.
    #
    # @param priv [String] binary string of private key data (optional).
    def initialize priv: nil

      # Creates a new, randomized libsecp256k1 context.
      ctx = Secp256k1::Context.new context_randomization_bytes: SecureRandom.random_bytes(32)

      # Creates a new random key pair (public, private).
      key = ctx.generate_key_pair

      unless priv.nil?

        # Creates a keypair from existing private key data.
        key = ctx.key_pair_from_private_key priv
      end

      # Sets the attributes.
      @private_key = key.private_key
      @public_key = key.public_key
    end

    # Converts the private key data into a hexa-decimal string.
    #
    # @returns [String] private key as hexa-decimal string.
    def private_hex
      Secp256k1::Util.bin_to_hex @private_key.data
    end

    # Exports the private key bytes in a wrapper function to maintain
    # backward-compatibility with older versions of `Eth::Key`.
    #
    # @returns [String] private key as packed byte-string.
    def private_bytes
      @private_key
    end

    # Converts the public key data into a hexa-decimal string.
    #
    # @returns [String] public key as hexa-decimal string.
    def public_hex
      Secp256k1::Util.bin_to_hex @public_key.uncompressed
    end

    # Exports the public key bytes in a wrapper function to maintain
    # backward-compatibility with older versions of `Eth::Key`.
    #
    # @returns [String] public key as packed byte-string.
    def public_bytes
      @public_key
    end
  end
end
