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

require "eth/ens/coin_type"
require "eth/ens/resolver"

# Provides the {Eth} module.
module Eth
  # Provides ENS specific functionality
  # ref: https://ens.domains
  module Ens
    extend self

    # The default address for ENS, which applies to most chains
    DEFAULT_ADDRESS = Address.new("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e").freeze
  end
end
