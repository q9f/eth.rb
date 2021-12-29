# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     attr_reader :http
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "rlp"
require "konstructor"
require "eth/tx/eip1559"
require "eth/tx/eip2930"
require "eth/tx/envelope"
require "eth/tx/legacy"

# Provides the `Eth` module.
module Eth

  # Provides the `Tx` module supporting various transaction types.
  module Tx

    # The minimum transaction gas limit required for a value transfer.
    DEFAULT_LIMIT = 21_000

    # The maximum transaction gas limit is bound by the block gas limit.
    BLOCK_LIMIT = 10_000_000
  end
end
