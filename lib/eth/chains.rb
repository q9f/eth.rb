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

  # Encapsulates `Chains` IDs and utilities for EIP-155 compatibility.
  # ref: https://eips.ethereum.org/EIPS/eip-155
  module Chains
    extend self

    # Chain IDs for selected mainnets
    ETHEREUM = 1
    EXPANSE = 2
    OPTIMISM = 10
    CLASSIC = 61
    POA_NET = 99
    XDAI = 100
    ARBITRUM = 42161

    # Chain IDs for selected testnets
    MORDEN = 2
    ROPSTEN = 3
    RINKEBY = 4
    GOERLI = 5
    KOTTI = 6
    KOVAN = 42
    MORDEN_CLASSIC = 62
    MORDOR = 63
    KOVAN_OPTIMISM = 69
    XDAI_ARBITRUM = 200
    GOERLI_OPTIMISM = 420
    RINKEBY_ARBITRUM = 421611

    # Chain IDs for selected private networks
    PRIVATE_GETH = 1337

    # Indicates wether the given `v` indicates a legacy chain value
    # without EIP-155 replay protection.
    #
    # @param v [Integer] the signature's `v` value
    # @return [Boolean] true if legacy value
    def is_legacy? v
      [27, 28].include? v
    end

    # Convert a given `v` value to an ECDSA recovery id for the given
    # EIP-155 chain ID.
    #
    # @param v [Integer] the signature's `v` value
    # @param chain [Integer] the chain id the signature was generated on.
    # @return [Integer] the recovery id corresponding to `v`.
    # @raise [ArgumentError] if the given `v` is invalid.
    def to_recov v, chain = ETHEREUM
      x = 0 + 2 * chain + 35
      y = 1 + 2 * chain + 35
      if  is_legacy? v
        return v - 27
      elsif [x, y].include? v
        return v - 35 - 2 * chain
      else
        raise ArgumentError, "Invalid v value for chain #{chain}. Invalid chain ID?"
      end
    end

    # Converts a recovery ID into the expected `v` on a given chain.
    #
    # @param recov [Integer] signature recovery id.
    # @param chain [Integer] the chain id the signature was generated on.
    # @return [Integer] the signature's `v` value.
    def to_v recov, chain = ETHEREUM
      v = 2 * chain + 35 + recov
    end
  end
end
