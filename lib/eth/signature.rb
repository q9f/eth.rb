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

require 'rbsecp256k1'

# Provides the `Eth` module.
module Eth

  # Defines handy tools for verifying and recovering signatures.
  module Signature
    extend self

    # Prefix message as per EIP-191 with 0x19 to ensure the data is not
    # valid RLP and thus not mistaken for a transaction.
    # EIP-191 Version byte: 0x45 (E)
    # ref: https://eips.ethereum.org/EIPS/eip-191
    #
    # @param message [String] the message string to be prefixed.
    # @return [String] an EIP-191 prefixed string
    def prefix_message message
      "\x19Ethereum Signed Message:\n#{message.size}#{message}"
    end

    # Recovers a uncompressed public key from a message and a signature
    # on a given chain.
    #
    # @param message [String] the message string.
    # @param signature [String] the hex string containing the signature.
    # @param chain_id [Integer] the chain ID used to sign.
    # @return [String] an uncompressed public key hex.
    def personal_recover message, signature, chain_id = Chains::ETHEREUM
      context = Secp256k1::Context.new
      rotated_signature = Utils.hex_to_bin(signature).bytes.rotate -1
      signature = rotated_signature[1..-1].pack 'c*'
      v = rotated_signature.first
      recovery_id = Chains.to_recovery_id v, chain_id
      recoverable_signature = context.recoverable_signature_from_compact signature, recovery_id
      prefixed_message = prefix_message message
      hashed_message = Utils.keccak256 prefixed_message
      public_key = recoverable_signature.recover_public_key hashed_message
      Utils.bin_to_hex public_key.uncompressed
    end
  end
end
