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

  # Provides constants
  module Unit

    # Ethereum unit 1 wei := 0.000000000000000001 Ether.
    WEI = 10 ** 0

    # Ethereum unit 1 babbage := 0.000000000000001 Ether or 1_000 wei.
    BABBAGE = 10 ** 3

    # Ethereum unit 1 lovelace := 0.000000000001 Ether or 1_000_000 wei.
    LOVELACE = 10 ** 6

    # Ethereum unit 1 shannon := 0.000000001 Ether or 1_000_000_000 wei.
    SHANNON = 10 ** 9

    # Ethereum unit 1 szabo := 0.000_001 Ether or 1_000_000_000_000 wei.
    SZABO = 10 ** 12

    # Ethereum unit 1 finney := 0.001 Ether or 1_000_000_000_000_000 wei.
    FINNEY = 10 ** 15

    # Ethereum unit 1 Ether := 1_000_000_000_000_000_000 wei.
    ETHER = 10 ** 18

    # Ethereum unit 1 Gwei := 0.000000001 Ether or 1_000_000_000 wei.
    # Same as shannon, but more commonly used (billion wei).
    GWEI = SHANNON
  end
end
