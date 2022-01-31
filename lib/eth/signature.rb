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

require "rbsecp256k1"

# Provides the {Eth} module.
module Eth

  # Defines handy tools for verifying and recovering signatures.
  module Signature
    extend self

    # Provides a special signature error if signature is invalid.
    class SignatureError < StandardError; end

    # EIP-191 prefix byte 0x19
    EIP191_PREFIX_BYTE = "\x19".freeze

    # EIP-712 version byte 0x01
    EIP712_VERSION_BYTE = "\x01".freeze

    # Prefix message as per EIP-191 with `0x19` to ensure the data is not
    # valid RLP and thus not mistaken for a transaction.
    # EIP-191 Version byte: `0x45` (`E`)
    # Ref: https://eips.ethereum.org/EIPS/eip-191
    #
    # @param message [String] the message string to be prefixed.
    # @return [String] an EIP-191 prefixed string.
    def prefix_message(message)
      "#{EIP191_PREFIX_BYTE}Ethereum Signed Message:\n#{message.size}#{message}"
    end

    # Dissects a signature blob of 65+ bytes into its `r`, `s`, and `v`
    # values.
    #
    # @param signature [String] a concatenated Secp256k1 signature string.
    # @return [String, String, String] the `r`, `s`, and `v` values.
    # @raise [SignatureError] if signature is of unknown size.
    def dissect(signature)
      signature = Util.bin_to_hex signature unless Util.is_hex? signature
      signature = Util.remove_hex_prefix signature
      if signature.size < 130
        raise SignatureError, "Unknown signature length #{signature.size}!"
      end
      r = signature[0, 64]
      s = signature[64, 64]
      v = signature[128..]
      return r, s, v
    end

    # Recovers a signature from arbitrary data without validation on a given chain.
    #
    # @param blob [String] that arbitrary data to be recovered.
    # @param signature [String] the hex string containing the signature.
    # @param chain_id [Integer] the chain ID the signature should be recovered from.
    # @return [String] a hexa-decimal, uncompressed public key.
    # @raise [SignatureError] if signature is of invalid size or invalid v.
    def recover(blob, signature, chain_id = Chain::ETHEREUM)
      context = Secp256k1::Context.new
      r, s, v = dissect signature
      v = v.to_i(16)
      raise SignatureError, "Invalid signature v byte #{v} for chain ID #{chain_id}!" if v < chain_id
      recovery_id = Chain.to_recovery_id v, chain_id
      signature_rs = Util.hex_to_bin "#{r}#{s}"
      recoverable_signature = context.recoverable_signature_from_compact signature_rs, recovery_id
      public_key = recoverable_signature.recover_public_key blob
      Util.bin_to_hex public_key.uncompressed
    end

    # Recovers a public key from a prefixed, personal message and
    # a signature on a given chain. (EIP-191)
    # Ref: https://eips.ethereum.org/EIPS/eip-191
    #
    # @param message [String] the message string.
    # @param signature [String] the hex string containing the signature.
    # @param chain_id [Integer] the chain ID the signature should be recovered from.
    # @return [String] a hexa-decimal, uncompressed public key.
    def personal_recover(message, signature, chain_id = Chain::ETHEREUM)
      prefixed_message = prefix_message message
      hashed_message = Util.keccak256 prefixed_message
      recover hashed_message, signature, chain_id
    end

    # Recovers a public key from a typed data structure and a signature
    # on a given chain. (EIP-712)
    # Ref: https://eips.ethereum.org/EIPS/eip-712
    #
    # @param typed_data [Array] all the data in the typed data structure to be recovered.
    # @param signature [String] the hex string containing the signature.
    # @param chain_id [Integer] the chain ID the signature should be recovered from.
    # @return [String] a hexa-decimal, uncompressed public key.
    def recover_typed_data(typed_data, signature, chain_id = Chain::ETHEREUM)
      hash_to_sign = Eip712.hash typed_data
      recover hash_to_sign, signature, chain_id
    end

    # Verifies a signature for a given public key or address.
    #
    # @param blob [String] that arbitrary data to be verified.
    # @param signature [String] the hex string containing the signature.
    # @param public_key [String] either a public key or an Ethereum address.
    # @param chain_id [Integer] the chain ID used to sign.
    # @return [Boolean] true if signature matches provided public key.
    # @raise [SignatureError] if it cannot determine the type of data or public key.
    def verify(blob, signature, public_key, chain_id = Chain::ETHEREUM)
      recovered_key = nil
      if blob.instance_of? Array or blob.instance_of? Hash

        # recover Array from sign_typed_data
        recovered_key = recover_typed_data blob, signature, chain_id
      elsif blob.instance_of? String and blob.encoding != Encoding::ASCII_8BIT

        # recover message from personal_sign
        recovered_key = personal_recover blob, signature, chain_id
      elsif blob.instance_of? String and (Util.is_hex? blob or blob.encoding == Encoding::ASCII_8BIT)

        # if nothing else, recover from arbitrary signature
        recovered_key = recover blob, signature, chain_id
      end

      # raise if we cannot determine the data format
      raise SignatureError, "Unknown data format to verify: #{blob}" if recovered_key.nil?

      if public_key.instance_of? Address

        # recovering using an Eth::Address
        address = public_key.to_s
        recovered_address = Util.public_key_to_address(recovered_key).to_s
        return address == recovered_address
      elsif public_key.instance_of? Secp256k1::PublicKey

        # recovering using an Secp256k1::PublicKey
        public_hex = Util.bin_to_hex public_key.uncompressed
        return public_hex == recovered_key
      elsif public_key.size == 42

        # recovering using an address String
        address = Address.new(public_key).to_s
        recovered_address = Util.public_key_to_address(recovered_key).to_s
        return address == recovered_address
      elsif public_key.size == 130

        # recovering using an uncompressed public key String
        return public_key == recovered_key
      else

        # raise if we cannot determine the public key format used
        raise SignatureError, "Invalid public key or address supplied #{public_key}!"
      end
    end
  end
end
