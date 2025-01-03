# Copyright (c) 2016-2025 The Ruby-Eth Contributors
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

  # Encapsulates {Eth::Chain} IDs and utilities for EIP-155 compatibility.
  # Ref: https://eips.ethereum.org/EIPS/eip-155
  module Chain
    extend self

    # Provides a special replay protection error if EIP-155 is violated.
    class ReplayProtectionError < StandardError; end

    # Chain ID for Ethereum mainnet.
    ETHEREUM = 1.freeze

    # Chain ID for Expanse mainnet.
    EXPANSE = 2.freeze

    # Chain ID for Optimistic Ethereum mainnet.
    OPTIMISM = 10.freeze

    # Chain ID for Cronos mainnet.
    CRONOS = 25.freeze

    # Chain ID for Rootstock mainnet.
    RSK = 30.freeze

    # Chain ID for BNB Smart Chain mainnet.
    BNB = 56.freeze

    # Chain ID for Ethereum Classic mainnet.
    CLASSIC = 61.freeze

    # Chain ID for POA Network mainnet.
    POA_NET = 99.freeze

    # Chain ID for xDAI mainnet (now Gnosis Chain).
    XDAI = 100.freeze

    # Chain ID for Gnosis mainnet (formerly xDAI).
    GNOSIS = XDAI.freeze

    # Chain ID for the Matic mainnet (now Polygon).
    MATIC = 137.freeze

    # Chain ID for the Polygon mainnet (formerly Matic).
    POLYGON = MATIC.freeze

    # Chain ID for Filecoin mainnet.
    FILECOIN = 314.freeze

    # Chain ID for the Cronos zkEVM chain.
    CRONOS_ZK = 388.freeze

    # Chain ID for Redstone Optimistic Rollup.
    REDSTONE = 690.freeze

    # Chain ID for the Polygon zkEVM.
    POLYGON_ZK = 1101.freeze

    # Chain ID for the Lisk layer 2.
    LISK = 1135.freeze

    # Chain ID for Moonbeam
    MOONBEAM = 1284.freeze

    # Chain ID for Base mainnet.
    BASE = 8453.freeze

    # Chain ID for the EVMOS mainnet.
    EVMOS = 9001.freeze

    # Chain ID for the Celo layer 2.
    CELO = 42220.freeze

    # Chain ID for Arbitrum One mainnet.
    ARBITRUM = 42161.freeze

    # Chain ID for Avalance C-Chain mainnet.
    AVALANCHE = 43114.freeze

    # Chain ID for Linea mainnet.
    LINEA = 59144.freeze

    # Chain ID for the Scroll layer 2.
    SCROLL = 534352.freeze

    # Chain ID for Morden (Ethereum) testnet.
    MORDEN = 2.freeze

    # Chain ID for Ropsten testnet.
    ROPSTEN = 3.freeze

    # Chain ID for Rinkeby testnet.
    RINKEBY = 4.freeze

    # Chain ID for Goerli testnet.
    GOERLI = 5.freeze

    # Chain ID for Kotti testnet.
    KOTTI = 6.freeze

    # Chain ID for Kovan testnet.
    KOVAN = 42.freeze

    # Chain ID for Morden (Classic) testnet.
    MORDEN_CLASSIC = 62.freeze

    # Chain ID for Mordor testnet.
    MORDOR = 63.freeze

    # Chain ID for Optimistm Kovan testnet.
    KOVAN_OPTIMISM = 69.freeze

    # Chain ID for Arbitrum xDAI testnet.
    XDAI_ARBITRUM = 200.freeze

    # Chain ID for Optimistic Goerli testnet.
    GOERLI_OPTIMISM = 420.freeze

    # Chain ID for Moonriver testnet
    MOONRIVER = 1285.freeze

    # Chain ID for Moonbase alpha
    MOONBASE = 1287.freeze

    # Chain ID for the Garnet Holesky testnet
    GARNET = 17069.freeze

    # Chain ID for the Polygon Mumbai testnet.
    MUMBAI = 80001.freeze

    # Chain ID for Arbitrum Rinkeby testnet.
    RINKEBY_ARBITRUM = 421611.freeze

    # Chain ID for Arbitrum Goerli testnet.
    GOERLI_ARBITRUM = 421613.freeze

    # Chain ID for Sepolia testnet.
    SEPOLIA = 11155111.freeze

    # Chain ID for Holesovice testnet.
    HOLESOVICE = 11166111.freeze
    HOLESKY = HOLESOVICE

    # Chain ID for the geth private network preset.
    PRIVATE_GETH = 1337.freeze

    # Indicates wether the given `v` indicates a legacy chain value
    # used by ledger wallets without EIP-155 replay protection.
    #
    # @param v [Integer] the signature's `v` value.
    # @return [Boolean] true if ledger's legacy value.
    def ledger?(v)
      [0, 1].include? v
    end

    # Indicates wether the given `v` indicates a legacy chain value
    # without EIP-155 replay protection.
    #
    # @param v [Integer] the signature's `v` value.
    # @return [Boolean] true if legacy value.
    def legacy?(v)
      [27, 28].include? v
    end

    # Convert a given `v` value to an ECDSA recovery id for the given
    # EIP-155 chain ID.
    #
    # @param v [Integer] the signature's `v` value.
    # @param chain_id [Integer] the chain id the signature was generated on.
    # @return [Integer] the recovery id corresponding to `v`.
    # @raise [ReplayProtectionError] if the given `v` is invalid.
    def to_recovery_id(v, chain_id = ETHEREUM)
      e = 0 + 2 * chain_id + 35
      i = 1 + 2 * chain_id + 35
      if ledger? v

        # some wallets are using a `v` of 0 or 1 (ledger)
        return v
      elsif legacy? v

        # this is the pre-EIP-155 legacy case
        return v - 27
      elsif [e, i].include? v

        # this is the EIP-155 case
        return v - 35 - 2 * chain_id
      else
        raise ReplayProtectionError, "Invalid v #{v} value for chain ID #{chain_id}. Invalid chain ID?"
      end
    end

    # Converts a recovery ID into the expected `v` on a given chain.
    #
    # @param recovery_id [Integer] signature recovery id.
    # @param chain_id [Integer] the chain id the signature was generated on.
    # @return [Integer] the signature's `v` value.
    def to_v(recovery_id, chain_id = nil)
      if chain_id.nil? or chain_id < 1
        v = 27 + recovery_id
      else
        v = 2 * chain_id + 35 + recovery_id
      end
      return v
    end

    # Converts a `v` value into a chain ID. This does not work for legacy signatures
    # with `v < 36` that do not conform with EIP-155.
    #
    # @param v [Integer] the signature's `v` value.
    # @return [Integer] the chain id as per EIP-155 or `nil` if there is no replay protection.
    def to_chain_id(v)
      return nil if v < 36
      chain_id = (v - 35) / 2
      return nil if chain_id < 1
      return chain_id
    end
  end
end
