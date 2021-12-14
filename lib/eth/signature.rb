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
    # @param msg [String] the message string to be prefixed.
    # @return [String] an EIP-191 prefixed string
    def prefix msg
      "\x19Ethereum Signed Message:\n#{msg.size}#{msg}"
    end

    # Recovers a uncompressed public key from a message and a signature
    # on a given chain.
    #
    # @param msg [String] the message string.
    # @param sig [String] the hex string containing the signature.
    # @param chain [Integer] the chain ID used to sign.
    # @return [String] an uncompressed public key hex.
    def personal_recover msg, sig, chain = Chains::ETHEREUM
      ctx = Secp256k1::Context.new
      rotated = Utils.hex_to_bin(sig).bytes.rotate -1
      sig = rotated[1..-1].pack 'c*'
      v = rotated.first
      recov = Chains.to_recov v, chain
      recov_sig = ctx.recoverable_signature_from_compact sig, recov
      prefixed = prefix msg
      hashed_pre = Utils.keccak256 prefixed
      pubk = recov_sig.recover_public_key hashed_pre
      Utils.bin_to_hex pubk.uncompressed
    end
  end
end
