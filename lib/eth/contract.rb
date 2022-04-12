require 'forwardable'

module Eth
  class Contract
    attr_reader :address
    attr_accessor :key
    attr_accessor :gas_limit, :gas_price, :max_fee_per_gas, :max_priority_fee_per_gas, :nonce
    attr_accessor :bin, :name, :abi, :class_object, :sender, :deployment, :client
    attr_accessor :events, :functions, :constructor_inputs
    attr_accessor :call_raw_proxy, :call_proxy, :transact_proxy, :transact_and_wait_proxy
    attr_accessor :new_filter_proxy, :get_filter_logs_proxy, :get_filter_change_proxy

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

    def deploy_payload(params)
      if @constructor_inputs.present?
        raise ArgumentError, "Wrong number of arguments in a constructor" and return if params.length != @constructor_inputs.length
      end
      deploy_arguments = @encoder.encode_arguments(@constructor_inputs, params)
      "0x" + @code + deploy_arguments
    end

    def deploy_args(params)
      add_gas_options_args({from: sender, data: deploy_payload(params)})
    end

    def send_transaction(tx_args)
      @client.eth_send_transaction(tx_args)["result"]
    end

    def send_raw_transaction(payload, to = nil)
      Eth.configure { |c| c.chain_id = @client.net_version["result"].to_i }
      @nonce ||= @client.get_nonce(key.address)
      args = {
        from: key.address,
        value: 0,
        data: payload,
        nonce: @nonce,
        gas_limit: gas_limit,
        gas_price: gas_price
      }
      args[:to] = to if to
      tx = Eth::Tx.new(args)
      tx.sign key
      @client.eth_send_raw_transaction(tx.hex)["result"]
    end

    def estimate(*params)
      result = @client.eth_estimate_gas(deploy_args(params))
      @decoder.decode_int(result["result"])
    end

    def transact(fun, *args)
      if key
        tx = send_raw_transaction(call_payload(fun, args), address)
      else
        tx = send_transaction(call_args(fun, args))
      end
      return Ethereum::Transaction.new(tx, @client, call_payload(fun, args), args)
    end

    def transact_and_wait(fun, *args)
      tx = transact(fun, *args)
      tx.wait_for_miner
      return tx
    end

    def create_filter(evt, **params)
      params[:to_block] ||= "latest"
      params[:from_block] ||= "0x0"
      params[:address] ||= @address
      params[:topics] = @encoder.ensure_prefix(evt.signature)
      payload = {topics: [params[:topics]], fromBlock: params[:from_block], toBlock: params[:to_block], address: @encoder.ensure_prefix(params[:address])}
      filter_id = @client.eth_new_filter(payload)
      return @decoder.decode_int(filter_id["result"])
    end

    def parse_filter_data(evt, logs)
      formatter = Eth::Contract::Formatter.new
      collection = []
      logs["result"].each do |result|
        inputs = evt.input_types
        outputs = inputs.zip(result["topics"][1..-1])
        data = {blockNumber: result["blockNumber"].hex, transactionHash: result["transactionHash"], blockHash: result["blockHash"], transactionIndex: result["transactionIndex"].hex, topics: []}
        outputs.each do |output|
          data[:topics] << formatter.from_payload(output)
        end
        collection << data
      end
      return collection
    end

    def get_filter_logs(evt, filter_id)
      parse_filter_data evt, @client.eth_get_filter_logs(filter_id)
    end

    def get_filter_changes(evt, filter_id)
      parse_filter_data evt, @client.eth_get_filter_changes(filter_id)
    end

    def function_name(fun)
      count = functions.select {|x| x.name == fun.name }.count
      name = (count == 1) ? "#{fun.name.underscore}" : "#{fun.name.underscore}__#{fun.inputs.collect {|x| x.type}.join("__")}"
      name.to_sym
    end

    def build
      class_name = @name
      parent = self
      create_function_proxies
      create_event_proxies
      class_methods = Class.new do
        extend Forwardable
        def_delegators :parent, :deploy_payload, :deploy_args, :call_payload, :call_args
        def_delegators :parent, :signed_deploy, :key, :key=
        def_delegators :parent, :gas_limit, :gas_price, :gas_limit=, :gas_price=, :nonce, :nonce=
        def_delegators :parent, :max_fee_per_gas, :max_fee_per_gas=, :max_priority_fee_per_gas, :max_priority_fee_per_gas=
        def_delegators :parent, :abi, :deployment, :events
        def_delegators :parent, :estimate, :deploy, :deploy_and_wait
        def_delegators :parent, :address, :address=, :sender, :sender=
        def_delegator :parent, :call_raw_proxy, :call_raw
        def_delegator :parent, :call_proxy, :call
        def_delegator :parent, :transact_proxy, :transact
        def_delegator :parent, :transact_and_wait_proxy, :transact_and_wait
        def_delegator :parent, :new_filter_proxy, :new_filter
        def_delegator :parent, :get_filter_logs_proxy, :get_filter_logs
        def_delegator :parent, :get_filter_change_proxy, :get_filter_changes
        def_delegator :parent, :functions
        define_method :parent do
          parent
        end
      end
      Eth::Contract.send(:remove_const, class_name) if Eth::Contract.const_defined?(class_name, false)
      Eth::Contract.const_set(class_name, class_methods)
      @class_object = class_methods
    end

    private

      def create_function_proxies
        parent = self
        call_raw_proxy, call_proxy, transact_proxy, transact_and_wait_proxy = Class.new, Class.new, Class.new, Class.new
        @functions.each do |fun|
          call_raw_proxy.send(:define_method, parent.function_name(fun)) { |*args| parent.call_raw(fun, *args) }
          call_proxy.send(:define_method, parent.function_name(fun)) { |*args| parent.call(fun, *args) }
          transact_proxy.send(:define_method, parent.function_name(fun)) { |*args| parent.transact(fun, *args) }
          transact_and_wait_proxy.send(:define_method, parent.function_name(fun)) { |*args| parent.transact_and_wait(fun, *args) }
        end
        @call_raw_proxy, @call_proxy, @transact_proxy, @transact_and_wait_proxy =  call_raw_proxy.new, call_proxy.new, transact_proxy.new, transact_and_wait_proxy.new
      end

      def create_event_proxies
        parent = self
        new_filter_proxy, get_filter_logs_proxy, get_filter_change_proxy = Class.new, Class.new, Class.new
        events.each do |evt|
          new_filter_proxy.send(:define_method, evt.name.underscore) { |*args| parent.create_filter(evt, *args) }
          get_filter_logs_proxy.send(:define_method, evt.name.underscore) { |*args| parent.get_filter_logs(evt, *args) }
          get_filter_change_proxy.send(:define_method, evt.name.underscore) { |*args| parent.get_filter_changes(evt, *args) }
        end
        @new_filter_proxy, @get_filter_logs_proxy, @get_filter_change_proxy = new_filter_proxy.new, get_filter_logs_proxy.new, get_filter_change_proxy.new
      end
  end
end

