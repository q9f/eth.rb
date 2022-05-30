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

# -*- encoding : ascii-8bit -*-

# Provides the {Eth} module.
module Eth

  # Provide classes for contract event.
  class Contract::Event
    attr_accessor :name, :signature, :input_types, :inputs, :event_string, :address

    # Constructor of the {Eth::Contract::Event} class.
    #
    # @param data [Hash] contract event data.
    def initialize(data)
      @name = data["name"]
      @input_types = data["inputs"].collect { |x| x["type"] }
      @inputs = data["inputs"].collect { |x| x["name"] }
      @event_string = "#{@name}(#{@input_types.join(",")})"
      @signature = Digest::Keccak.hexdigest(@event_string, 256)
    end

    # Set the address of the smart contract
    #
    # @param address [String] contract address.
    def set_address(address)
      @address = address.nil? ? nil : Eth::Address.new(address).address
    end
  end
end
