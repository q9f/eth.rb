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
require "eth/contract/event"
require "eth/contract/function"
require "eth/contract/function_input"
require "eth/contract/function_output"
require "eth/contract/initializer"
require "eth/client"
require "eth/client/http"
require "eth/client/ipc"
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

# Provides shorthand for using these types
#
# @example Creating a new Hex object
#   Hex("0x0fff").to_i
#     => 
module Eth
  # Num = -> { Types::Num.new }
  # Hex = -> (string) { Types::Hex.new(string) }
  # Dec = -> (str_or_int) { Types::Dec.new(str_or_int) }
  # Bin = -> (string) { Types::Bin.new(string) }

  module_eval do
   def Num() Types::Num.new end
   def Hex(string) Types::Hex.new(string) end
   def Bin(string) Types::Bin.new(string) end
   def Dec(str_or_int) Types::Dec.new(str_or_int) end
  end
end


