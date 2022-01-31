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

require "bigdecimal"

# Provides the {Eth} module.
module Eth

  # Provides constants for common Ethereum units.
  module Unit
    extend self

    # Ethereum unit 1 wei := 0.000000000000000001 Ether.
    WEI = BigDecimal("1e0").freeze

    # Ethereum unit 1 babbage := 0.000000000000001 Ether or 1_000 wei.
    BABBAGE = BigDecimal("1e3").freeze

    # Ethereum unit 1 lovelace := 0.000000000001 Ether or 1_000_000 wei.
    LOVELACE = BigDecimal("1e6").freeze

    # Ethereum unit 1 shannon := 0.000000001 Ether or 1_000_000_000 wei.
    SHANNON = BigDecimal("1e9").freeze

    # Ethereum unit 1 szabo := 0.000_001 Ether or 1_000_000_000_000 wei.
    SZABO = BigDecimal("1e12").freeze

    # Ethereum unit 1 finney := 0.001 Ether or 1_000_000_000_000_000 wei.
    FINNEY = BigDecimal("1e15").freeze

    # Ethereum unit 1 Ether := 1_000_000_000_000_000_000 wei.
    ETHER = BigDecimal("1e18").freeze

    # Ethereum unit 1 Gwei := 0.000000001 Ether or 1_000_000_000 wei.
    # Same as shannon, but more commonly used (billion wei).
    GWEI = SHANNON.freeze
  end
end
