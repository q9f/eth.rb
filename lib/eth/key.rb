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

require "json"
require "openssl"
require "rbsecp256k1"
require "scrypt"
require "securerandom"

# Provides the {Eth} module.
module Eth

  # The {Eth::Key} class to handle Secp256k1 private/public key-pairs.
  class Key

    # The {Eth::Key::Decrypter} class to handle PBKDF2-SHA-256 decryption.
    autoload :Decrypter, "eth/key/decrypter"

    # The {Eth::Key::Encrypter} class to handle PBKDF2-SHA-256 encryption.
    autoload :Encrypter, "eth/key/encrypter"

    # The `Secp256k1::PrivateKey` of the {Eth::Key} pair.
    attr_reader :private_key

    # The `Secp256k1::PublicKey` of the {Eth::Key} pair.
    attr_reader :public_key

    # Constructor of the {Eth::Key} class. Creates a new random key-pair
    # if no `priv` key is provided.
    #
    # @param priv [String] binary string of private key data.
    def initialize(priv: nil)

      # Creates a new, randomized libsecp256k1 context.
      ctx = Secp256k1::Context.new context_randomization_bytes: SecureRandom.random_bytes(32)

      # Creates a new random key pair (public, private).
      key = ctx.generate_key_pair

      unless priv.nil?

        # Converts hex private keys to binary strings.
        priv = Util.hex_to_bin priv if Util.is_hex? priv

        # Creates a keypair from existing private key data.
        key = ctx.key_pair_from_private_key priv
      end

      # Sets the attributes.
      @private_key = key.private_key
      @public_key = key.public_key
    end

    # Signs arbitrary data without validation. Should not be used unless really
    # desired. See also: {Key.personal_sign}, {Key.sign_typed_data}, and
    # {Signature.recover}.
    #
    # @param blob [Object] that arbitrary data to be signed.
    # @param chain_id [Integer] the chain id the signature should be generated on.
    # @return [String] a hexa-decimal signature.
    def sign(blob, chain_id = nil)
      context = Secp256k1::Context.new
      compact, recovery_id = context.sign_recoverable(@private_key, blob).compact
      signature = compact.bytes
      v = Chain.to_v recovery_id, chain_id
      is_leading_zero = true
      [v].pack("N").unpack("C*").each do |byte|
        is_leading_zero = false if byte > 0 and is_leading_zero
        signature.append byte unless is_leading_zero and byte === 0
      end
      Util.bin_to_hex signature.pack "c*"
    end

    # Prefixes a message with `\x19Ethereum Signed Message:` and signs
    # it in the common way used by many web3 wallets. Complies with
    # EIP-191 prefix `0x19` and version byte `0x45` (`E`). See also
    # {Signature.personal_recover}.
    # Ref: https://eips.ethereum.org/EIPS/eip-191
    #
    # @param message [String] the message string to be prefixed and signed.
    # @param chain_id [Integer] the chain id the signature should be generated on.
    # @return [String] an EIP-191 conform, hexa-decimal signature.
    def personal_sign(message, chain_id = nil)
      prefixed_message = Signature.prefix_message message
      hashed_message = Util.keccak256 prefixed_message
      sign hashed_message, chain_id
    end

    # Prefixes, hashes, and signes a typed data structure in the common
    # way used by many web3 wallets. Complies with EIP-191 prefix `0x19`
    # and EIP-712 version byte `0x01`. Supports `V3`, `V4`. See also
    # {Signature.recover_typed_data}.
    # Ref: https://eips.ethereum.org/EIPS/eip-712
    #
    # @param typed_data [Array] all the data in the typed data structure to be signed.
    # @param chain_id [Integer] the chain id the signature should be generated on.
    # @return [String] an EIP-712 conform, hexa-decimal signature.
    def sign_typed_data(typed_data, chain_id = nil)
      hash_to_sign = Eip712.hash typed_data
      sign hash_to_sign, chain_id
    end

    # Converts the private key data into a hexa-decimal string.
    #
    # @return [String] private key as hexa-decimal string.
    def private_hex
      Util.bin_to_hex @private_key.data
    end

    # Exports the private key bytes in a wrapper function to maintain
    # backward-compatibility with older versions of {Eth::Key}.
    #
    # @return [String] private key as packed byte-string.
    def private_bytes
      @private_key.data
    end

    # Converts the public key data into an uncompressed
    # hexa-decimal string.
    #
    # @return [String] public key as uncompressed hexa-decimal string.
    def public_hex
      Util.bin_to_hex @public_key.uncompressed
    end

    # Converts the public key data into an compressed
    # hexa-decimal string.
    #
    # @return [String] public key as compressed hexa-decimal string.
    def public_hex_compressed
      Util.bin_to_hex @public_key.compressed
    end

    # Exports the uncompressed public key bytes in a wrapper function to
    # maintain backward-compatibility with older versions of {Eth::Key}.
    #
    # @return [String] uncompressed public key as packed byte-string.
    def public_bytes
      @public_key.uncompressed
    end

    # Exports the compressed public key bytes.
    #
    # @return [String] compressed public key as packed byte-string.
    def public_bytes_compressed
      @public_key.compressed
    end

    # Exports the checksummed public address.
    #
    # @return [Eth::Address] compressed address as packed hex prefixed string.
    def address
      Util.public_key_to_address public_bytes
    end
  end
end
