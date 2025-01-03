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
  # Provides ENS specific functionality
  # ref: https://ens.domains
  module Ens
    # Provides EIP-2304 / SLIP-44 cointypes to resolve ENS addresses.
    # ref: https://eips.ethereum.org/EIPS/eip-2304
    module CoinType
      extend self

      # ENS coin type for Bitcoin.
      BITCOIN = 0.freeze

      # ENS coin type for Litecoin.
      LITECOIN = 2.freeze

      # ENS coin type for Dogecoin.
      DOGECOIN = 3.freeze

      # ENS coin type for Ethereum.
      ETHEREUM = 60.freeze

      # ENS coin type for Ethereum Classic.
      ETHEREUM_CLASSIC = 61.freeze

      # ENS coin type for Rootstock.
      ROOTSTOCK = 137.freeze

      # ENS coin type for Bitcoin Cash.
      BITCOIN_CASH = 145.freeze

      # ENS coin type for Binance.
      BINANCE = 714.freeze
    end
  end
end
