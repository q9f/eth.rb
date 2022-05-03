require 'forwardable'

module Eth
  class Contract
    attr_reader :address
    attr_accessor :key
    attr_accessor :gas_limit, :gas_price, :max_fee_per_gas, :max_priority_fee_per_gas, :nonce
    attr_accessor :bin, :name, :abi, :class_object
    attr_accessor :events, :functions, :constructor_inputs

    def initialize(name, bin, abi)
      @name = name
      @bin = bin
      @abi = abi
      @constructor_inputs, @functions, @events = Eth::Contract::Abi.parse_abi(abi)
    end

    # Creates a contract wrapper.
    #
    # @param file [String] solidity file path.
    # @param bin [String] contract bin string.
    # @param abi [String] contract abi string.
    # @param address [String] contract address.
    # @param name [String] name of contract.
    # @param contract_index [Number] specify contract.
    # @return [Eth::Contract::Object] Returns the class of the smart contract.
    # @raise [JSON::ParserError] if the json format is wrong.
    # @raise [ArgumentError] if argument is incorrect.
    def self.create(file: nil, bin: nil, abi: nil, address: nil, name: nil, contract_index: nil)
      if File.exist?(file.to_s)
        contracts = Eth::Contract::Initializer.new(file).build_all
        raise "No contracts compiled" if contracts.empty?
        if contract_index
          contract = contracts[contract_index].class_object.new
        else
          contract = contracts.first.class_object.new
        end
      elsif ![name, bin, abi].include? nil
        begin
          abi = abi.is_a?(Array) ? abi : JSON.parse(abi)
        rescue JSON::ParserError => e
          raise e
        end
        contract = Eth::Contract.new(name, bin, abi)
        contract.build
        contract = contract.class_object.new
      else
        raise ArgumentError, "The argument is incorrect."
      end
      contract.address = address
      contract
    end

    # Set the address of the smart contract
    def address=(addr)
      @address = addr.nil? ? nil : Eth::Address.new(addr).address
      @events.each do |event|
        event.set_address(@address)
      end
    end

    # Create classes for smart contracts
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
        define_method :parent do
          parent
        end
      end
      Eth::Contract.send(:remove_const, class_name) if Eth::Contract.const_defined?(class_name, false)
      Eth::Contract.const_set(class_name, class_methods)
      @class_object = class_methods
    end
  end
end
