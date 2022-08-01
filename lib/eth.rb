# frozen_string_literal: true
#
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

# Provides the {Eth} module.
module Eth
end

# Loads the {Eth} module classes.
require "eth/abi"
require "eth/api"
require "eth/address"
require "eth/chain"
require "eth/constant"
require "eth/contract"
require "eth/client"
require "eth/eip712"
require "eth/key"
require "eth/rlp"
require "eth/signature"
require "eth/solidity"
require "eth/tx"
require "eth/types/num"
require "eth/types/dec"
require "eth/types/hex"
require "eth/types/bin"
require "eth/unit"
require "eth/util"
require "eth/version"

module Eth

  module_function
  # @see {Eth::Types::Num}
  def Num() Eth::Types::Num.new end

  # @see {Eth::Types::Hex}
  def Hex(str_or_int) Eth::Types::Hex.new(str_or_int) end

  # @see {Eth::Types::Bin}
  def Bin(string) Eth::Types::Bin.new(string) end

  # @see {Eth::Types::Dec}
  def Dec(str_or_int) Eth::Types::Dec.new(str_or_int) end
end


