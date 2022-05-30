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

  # Provides classes to access smart contracts
  class Contract
    attr_reader :address
    attr_accessor :key
    attr_accessor :gas_limit, :gas_price, :max_fee_per_gas, :max_priority_fee_per_gas, :nonce
    attr_accessor :bin, :name, :abi, :class_object
    attr_accessor :events, :functions, :constructor_inputs

    # Constructor of the {Eth::Contract} class.
    #
    # @param name [String] contract name.
    # @param bin [String] contract bin string.
    # @param abi [String] contract abi string.
    def initialize(name, bin, abi)
      @name = name
      @bin = bin
      @abi = abi
      @constructor_inputs, @functions, @events = parse_abi(abi)
    end

    # Creates a contract wrapper from a Solidity file.
    #
    # @param file [String] solidity file path.
    # @param contract_index [Number] specify contract.
    # @return [Eth::Contract::Object] Returns the class of the smart contract.
    # @raise [ArgumentError] if the file path is empty or no contracts were compiled.
    def self.from_file(file:, contract_index: 0)
      raise ArgumentError, "Cannot find the contract at #{file.to_s}!" if !File.exist?(file.to_s)
      contracts = Eth::Contract::Initializer.new(file).build_all
      raise ArgumentError, "No contracts compiled." if contracts.empty?
      contracts[contract_index].class_object.new
    end

    # Creates a contract wrapper from ABI and address.
    #
    # @param abi [String] contract abi string.
    # @param address [String] contract address.
    # @param name [String] name of contract.
    # @return [Eth::Contract::Object] Returns the class of the smart contract.
    # @raise [JSON::ParserError] if the json format is wrong.
    # @raise [ArgumentError] if ABI, address, or name is missing.
    def self.from_abi(abi:, address:, name:)
      abi = abi.is_a?(Array) ? abi : JSON.parse(abi)
      contract = Eth::Contract.new(name, nil, abi)
      contract.build
      contract = contract.class_object.new
      contract.address = address
      contract
    end

    # Creates a contract wrapper from binary and ABI.
    #
    # @param bin [String] contract bin string.
    # @param abi [String] contract abi string.
    # @param name [String] name of contract.
    # @return [Eth::Contract::Object] Returns the class of the smart contract.
    # @raise [JSON::ParserError] if the json format is wrong.
    # @raise [ArgumentError] if ABI, binary, or name is missing.
    def self.from_bin(bin:, abi:, name:)
      abi = abi.is_a?(Array) ? abi : JSON.parse(abi)
      contract = Eth::Contract.new(name, bin, abi)
      contract.build
      contract.class_object.new
    end

    # Sets the address of the smart contract.
    #
    # @param addr [String|Eth::Address] contract address string.
    def address=(addr)
      if addr.is_a? Eth::Address
        @address = addr.to_s
      else
        @address = Eth::Address.new(addr).to_s
      end
      @events.each do |event|
        event.set_address(@address)
      end
    end

    # Create meta classes for smart contracts.
    def build
      class_name = @name
      parent = self
      class_methods = Class.new do
        extend Forwardable
        def_delegators :parent, :key, :key=
        def_delegators :parent, :name, :abi, :bin
        def_delegators :parent, :gas_limit, :gas_price, :gas_limit=, :gas_price=, :nonce, :nonce=
        def_delegators :parent, :max_fee_per_gas, :max_fee_per_gas=, :max_priority_fee_per_gas, :max_priority_fee_per_gas=
        def_delegators :parent, :events
        def_delegators :parent, :address, :address=
        def_delegator :parent, :functions
        def_delegator :parent, :constructor_inputs
        define_method :parent do
          parent
        end
      end
      Eth::Contract.send(:remove_const, class_name) if Eth::Contract.const_defined?(class_name, false)
      Eth::Contract.const_set(class_name, class_methods)
      @class_object = class_methods
    end

    private

    def parse_abi(abi)
      constructor = abi.detect { |x| x["type"] == "constructor" }
      if !constructor.nil?
        constructor_inputs = constructor["inputs"].map { |input| Eth::Contract::FunctionInput.new(input) }
      else
        constructor_inputs = []
      end
      functions = abi.select { |x| x["type"] == "function" }.map { |fun| Eth::Contract::Function.new(fun) }
      events = abi.select { |x| x["type"] == "event" }.map { |evt| Eth::Contract::Event.new(evt) }
      [constructor_inputs, functions, events]
    end
  end
end

# Load the contract/* libraries
require "eth/contract/event"
require "eth/contract/function"
require "eth/contract/function_input"
require "eth/contract/function_output"
require "eth/contract/initializer"
