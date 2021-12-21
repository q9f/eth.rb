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

# Provides the `Eth` module.
module Eth

  # Encapsulates `Chain` IDs and utilities for EIP-155 compatibility.
  # ref: https://eips.ethereum.org/EIPS/eip-155
  module Chain
    extend self

    # Chain ID for Ethereum mainnet
    ETHEREUM = 1

    # Chain ID for Expanse mainnet
    EXPANSE = 2

    # Chain ID for Optimistic Ethereum mainnet
    OPTIMISM = 10

    # Chain ID for Ethereum Classic mainnet
    CLASSIC = 61

    # Chain ID for POA Network mainnet
    POA_NET = 99

    # Chain ID for xDAI mainnet
    XDAI = 100

    # Chain ID for Arbitrum mainnet
    ARBITRUM = 42161

    # Chain ID for Morden (Ethereum) testnet
    MORDEN = 2

    # Chain ID for Ropsten testnet
    ROPSTEN = 3

    # Chain ID for Rinkeby testnet
    RINKEBY = 4

    # Chain ID for Goerli testnet
    GOERLI = 5

    # Chain ID for Kotti testnet
    KOTTI = 6

    # Chain ID for Kovan testnet
    KOVAN = 42

    # Chain ID for Morden (Classic) testnet
    MORDEN_CLASSIC = 62

    # Chain ID for Mordor testnet
    MORDOR = 63

    # Chain ID for Optimistik Kovan testnet
    KOVAN_OPTIMISM = 69

    # Chain ID for Arbitrum xDAI testnet
    XDAI_ARBITRUM = 200

    # Chain ID for Optimistic Goerli testnet
    GOERLI_OPTIMISM = 420

    # Chain ID for Arbitrum Rinkeby testnet
    RINKEBY_ARBITRUM = 421611

    # Chain ID for the geth private network preset
    PRIVATE_GETH = 1337

    # Indicates wether the given `v` indicates a legacy chain value
    # without EIP-155 replay protection.
    #
    # @param v [Integer] the signature's `v` value
    # @return [Boolean] true if legacy value
    def is_legacy?(v)
      [27, 28].include? v
    end

    # Convert a given `v` value to an ECDSA recovery id for the given
    # EIP-155 chain ID.
    #
    # @param v [Integer] the signature's `v` value
    # @param chain_id [Integer] the chain id the signature was generated on.
    # @return [Integer] the recovery id corresponding to `v`.
    # @raise [ArgumentError] if the given `v` is invalid.
    def to_recovery_id(v, chain_id = ETHEREUM)
      e = 0 + 2 * chain_id + 35
      i = 1 + 2 * chain_id + 35
      if [0, 1].include? v

        # some wallets are using a `v` of 0 or 1 (ledger)
        return v
      elsif is_legacy? v

        # this is the pre-EIP-155 legacy case
        return v - 27
      elsif [e, i].include? v

        # this is the EIP-155 case
        return v - 35 - 2 * chain_id
      else
        raise ArgumentError, "Invalid v #{v} value for chain ID #{chain_id}. Invalid chain ID?"
      end
    end

    # Converts a recovery ID into the expected `v` on a given chain.
    #
    # @param recovery_id [Integer] signature recovery id.
    # @param chain_id [Integer] the chain id the signature was generated on.
    # @return [Integer] the signature's `v` value.
    def to_v(recovery_id, chain_id = ETHEREUM)
      v = 2 * chain_id + 35 + recovery_id
    end
  end
end
