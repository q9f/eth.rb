require 'forwardable'

module Eth
  class Contract
    attr_reader :address
    attr_accessor :key
    attr_accessor :gas_limit, :gas_price, :max_fee_per_gas, :max_priority_fee_per_gas, :nonce
    attr_accessor :bin, :name, :abi, :class_object, :sender, :deployment, :client
    attr_accessor :events, :functions, :constructor_inputs

    def initialize(name, bin, abi)
      @name = name
      @bin = bin
      @abi = abi
      @constructor_inputs, @functions, @events = Eth::Contract::Abi.parse_abi(abi)
    end

    # Creates a contract wrapper.
    def self.create(file: nil, bin: nil, abi: nil, address: nil, name: nil, contract_index: nil)
      contract = nil
      if File.exist?(file)
        contracts = Eth::Contract::Initializer.new(file).build_all
        raise "No contracts compiled" if contracts.empty?
        if contract_index
          contract = contracts[contract_index].class_object.new
        else
          contract = contracts.first.class_object.new
        end
      else
        abi = abi.is_a?(String) ? JSON.parse(abi) : abi.map(&:deep_stringify_keys)
        contract = Eth::Contract.new(name, bin, abi)
        contract.build
        contract = contract.class_object.new
      end
      contract.address = address
      contract
    end

    def address=(addr)
      @address = addr.nil? ? nil : Eth::Address.new(addr).address
      @events.each do |event|
        event.set_address(@address)
        event.set_client(@client)
      end
    end

    def function_name(fun)
      count = functions.select {|x| x.name == fun.name }.count
      name = (count == 1) ? "#{fun.name.underscore}" : "#{fun.name.underscore}__#{fun.inputs.collect {|x| x.type}.join("__")}"
      name.to_sym
    end

    def build
      class_name = @name
      parent = self
      class_methods = Class.new do
        extend Forwardable
        def_delegators :parent, :key, :key=
        def_delegators :parent, :gas_limit, :gas_price, :gas_limit=, :gas_price=, :nonce, :nonce=
        def_delegators :parent, :max_fee_per_gas, :max_fee_per_gas=, :max_priority_fee_per_gas, :max_priority_fee_per_gas=
        def_delegators :parent, :abi, :deployment, :events
        def_delegators :parent, :address, :address=, :sender, :sender=
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

