# Copyright (c) 2016-2023 The Ruby-Eth Contributors
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

  # Provides the {Eth::Client} super-class to connect to Ethereum
  # network's RPC-API endpoints (IPC or HTTP).
  class Client

    # The client's RPC-request ID starting at 0.
    attr_reader :id

    # The connected network's chain ID.
    attr_reader :chain_id

    # The connected network's client coinbase.
    attr_accessor :default_account

    # The default transaction max priority fee per gas in Wei, defaults to {Tx::DEFAULT_PRIORITY_FEE}.
    attr_accessor :max_priority_fee_per_gas

    # The default transaction max fee per gas in Wei, defaults to {Tx::DEFAULT_GAS_PRICE}.
    attr_accessor :max_fee_per_gas

    # The block number used for archive calls.
    attr_accessor :block_number

    # A custom error type if a contract interaction fails.
    class ContractExecutionError < StandardError; end

    # Creates a new RPC-Client, either by providing an HTTP/S host or
    # an IPC path. Supports basic authentication with username and password.
    #
    # **Note**, this sets the folling gas defaults: {Tx::DEFAULT_PRIORITY_FEE}
    # and {Tx::DEFAULT_GAS_PRICE. Use {#max_priority_fee_per_gas} and
    # {#max_fee_per_gas} to set custom values prior to submitting transactions.
    #
    # @param host [String] either an HTTP/S host or an IPC path.
    # @return [Eth::Client::Ipc] an IPC client.
    # @return [Eth::Client::Http] an HTTP client.
    # @raise [ArgumentError] in case it cannot determine the client type.
    def self.create(host)
      return Client::Ipc.new host if host.end_with? ".ipc"
      return Client::Http.new host if host.start_with? "http"
      raise ArgumentError, "Unable to detect client type!"
    end

    # Constructor for the {Eth::Client} super-class. Should not be used;
    # use {Client.create} intead.
    def initialize(_)
      @id = 0
      @max_priority_fee_per_gas = Tx::DEFAULT_PRIORITY_FEE
      @max_fee_per_gas = Tx::DEFAULT_GAS_PRICE
    end

    # Gets the default account (coinbase) of the connected client.
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts.
    #
    # @return [Eth::Address] the coinbase account address.
    def default_account
      raise ArgumentError, "The default account is not available on remote connections!" unless local? || @default_account
      @default_account ||= Address.new eth_coinbase["result"]
    end

    # Gets the chain ID of the connected network.
    #
    # @return [Integer] the chain ID.
    def chain_id
      @chain_id ||= eth_chain_id["result"].to_i 16
    end

    # Gets the balance for an address.
    #
    # @param address [Eth::Address] the address to get the balance for.
    # @return [Integer] the balance in Wei.
    def get_balance(address)
      eth_get_balance(address)["result"].to_i 16
    end

    # Gets the next nonce for an address used to draft new transactions.
    #
    # @param address [Eth::Address] the address to get the nonce for.
    # @return [Integer] the next nonce to be used.
    def get_nonce(address)
      eth_get_transaction_count(address, "pending")["result"].to_i 16
    end

    # Resolves an ENS name to an Ethereum address on the connected chain.
    #
    # @param ens_name [String] The ENS name, e.g., `fancy.eth`.
    # @param registry [String] the address for the ENS registry.
    # @param coin_type [Integer] the coin type as per EIP-2304.
    # @return [Eth::Address] the Ethereum address resolved from the ENS record.
    def resolve_ens(ens_name, registry = Ens::DEFAULT_ADDRESS, coin_type = Ens::CoinType::ETHEREUM)
      ens = Ens::Resolver.new(self, registry)
      ens.resolve(ens_name, coin_type)
    end

    # Simply transfer Ether to an account and waits for it to be mined.
    # Uses `eth_coinbase` and external signer if no sender key is
    # provided.
    #
    # See {#transfer} for params and overloads.
    #
    # @return [String] the transaction hash once it is mined.
    def transfer_and_wait(destination, amount, **kwargs)
      wait_for_tx(transfer(destination, amount, **kwargs))
    end

    # Simply transfer Ether to an account without any call data or
    # access lists attached. Uses `eth_coinbase` and external signer
    # if no sender key is provided.
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts. Provide a `sender_key:` if you experience issues.
    #
    # @overload transfer(destination, amount)
    #   @param destination [Eth::Address] the destination address.
    #   @param amount [Integer] the transfer amount in Wei.
    # @overload transfer(destination, amount, **kwargs)
    #   @param destination [Eth::Address] the destination address.
    #   @param amount [Integer] the transfer amount in Wei.
    #   @param **sender_key [Eth::Key] the sender private key.
    #   @param **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    #   @param **nonce [Integer] optional specific nonce for transaction.
    # @return [String] the local transaction hash.
    def transfer(destination, amount, **kwargs)
      params = {
        value: amount,
        to: destination,
        gas_limit: Tx::DEFAULT_GAS_LIMIT,
        chain_id: chain_id,
      }
      send_transaction(params, kwargs[:legacy], kwargs[:sender_key], kwargs[:nonce])
    end

    # Transfers a token that implements the ERC20 `transfer()` interface.
    #
    # See {#transfer_erc20} for params and overloads.
    #
    # @return [Object] returns the result of the transaction.
    def transfer_erc20_and_wait(erc20_contract, destination, amount, **kwargs)
      transact_and_wait(erc20_contract, "transfer", destination, amount, **kwargs)
    end

    # Transfers a token that implements the ERC20 `transfer()` interface.
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts. Provide a `sender_key:` if you experience issues.
    #
    # @overload transfer_erc20(erc20_contract, destination, amount)
    #   @param erc20_contract [Eth::Contract] the ERC20 contract to write to.
    #   @param destination [Eth::Address] the destination address.
    #   @param amount [Integer] the transfer amount (mind the `decimals()`).
    # @overload transfer_erc20(erc20_contract, destination, amount, **kwargs)
    #   @param erc20_contract [Eth::Contract] the ERC20 contract to write to.
    #   @param destination [Eth::Address] the destination address.
    #   @param amount [Integer] the transfer amount (mind the `decimals()`).
    #   @param **sender_key [Eth::Key] the sender private key.
    #   @param **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    #   @param **gas_limit [Integer] optional gas limit override for the transfer.
    #   @param **nonce [Integer] optional specific nonce for transaction.
    #   @param **tx_value [Integer] optional transaction value field filling.
    # @return [Object] returns the result of the transaction.
    def transfer_erc20(erc20_contract, destination, amount, **kwargs)
      destination = destination.to_s if destination.instance_of? Eth::Address
      transact(erc20_contract, "transfer", destination, amount, **kwargs)
    end

    # Deploys a contract and waits for it to be mined. Uses
    # `eth_coinbase` or external signer if no sender key is provided.
    #
    # See {#deploy} for params and overloads.
    #
    # @return [String] the contract address once it's mined.
    def deploy_and_wait(contract, *args, **kwargs)
      hash = wait_for_tx(deploy(contract, *args, **kwargs))
      addr = eth_get_transaction_receipt(hash)["result"]["contractAddress"]
      contract.address = Address.new(addr).to_s
    end

    # Deploys a contract. Uses `eth_coinbase` or external signer
    # if no sender key is provided.
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts. Provide a `sender_key:` if you experience issues.
    #
    # @overload deploy(contract)
    #   @param contract [Eth::Contract] contracts to deploy.
    # @overload deploy(contract, *args)
    #   @param contract [Eth::Contract] the contracts to deploy.
    #   @param *args (optional) variable constructor parameter list.
    # @overload deploy(contract, *args, **kwargs)
    #   @param contract [Eth::Contract] the contracts to deploy.
    #   @param *args (optional) variable constructor parameter list.
    #   @param **sender_key [Eth::Key] the sender private key.
    #   @param **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    #   @param **gas_limit [Integer] optional gas limit override for deploying the contract.
    #   @param **nonce [Integer] optional specific nonce for transaction.
    # @return [String] the transaction hash.
    # @raise [ArgumentError] in case the contract does not have any source.
    def deploy(contract, *args, **kwargs)
      raise ArgumentError, "Cannot deploy contract without source or binary!" if contract.bin.nil?
      raise ArgumentError, "Missing contract constructor params!" if contract.constructor_inputs.length != args.length
      data = contract.bin
      unless args.empty?
        data += encode_constructor_params(contract, args)
      end
      gas_limit = if kwargs[:gas_limit]
          kwargs[:gas_limit]
        else
          Tx.estimate_intrinsic_gas(data) + Tx::CREATE_GAS
        end
      params = {
        value: 0,
        gas_limit: gas_limit,
        chain_id: chain_id,
        data: data,
      }
      send_transaction(params, kwargs[:legacy], kwargs[:sender_key], kwargs[:nonce])
    end

    # Calls a contract function without executing it
    # (non-transactional contract read).
    #
    # @overload call(contract, function)
    #   @param contract [Eth::Contract] the subject contract to call.
    #   @param function [String] method name to be called.
    # @overload call(contract, function, *args)
    #   @param contract [Eth::Contract] the subject contract to call.
    #   @param function [String] method name to be called.
    #   @param *args optional function arguments.
    # @overload call(contract, function, *args, **kwargs)
    #   @param contract [Eth::Contract] the subject contract to call.
    #   @param function [String] method name to be called.
    #   @param *args optional function arguments.
    #   @param **sender_key [Eth::Key] the sender private key.
    #   @param **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [Object] returns the result of the call.
    def call(contract, function, *args, **kwargs)
      func = contract.functions.select { |func| func.name == function }
      raise ArgumentError, "this function does not exist!" if func.nil? || func.size === 0
      selected_func = func.first
      func.each do |f|
        if f.inputs.size === args.size
          selected_func = f
        end
      end
      output = call_raw(contract, selected_func, *args, **kwargs)
      if output&.length == 1
        output[0]
      else
        output
      end
    end

    # Executes a contract function with a transaction (transactional
    # contract read/write).
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts. Provide a `sender_key:` if you experience issues.
    #
    # @overload transact(contract, function)
    #   @param contract [Eth::Contract] the subject contract to write to.
    #   @param function [String] method name to be executed.
    # @overload transact(contract, function, *args)
    #   @param contract [Eth::Contract] the subject contract to write to.
    #   @param function [String] method name to be executed.
    #   @param *args optional function arguments.
    # @overload transact(contract, function, *args, **kwargs)
    #   @param contract [Eth::Contract] the subject contract to write to.
    #   @param function_name [String] method name to be executed.
    #   @param *args optional function arguments.
    #   @param **sender_key [Eth::Key] the sender private key.
    #   @param **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    #   @param **address [Eth::Address] contract address.
    #   @param **gas_limit [Integer] optional gas limit override for transacting with the contract.
    #   @param **nonce [Integer] optional specific nonce for transaction.
    #   @param **tx_value [Integer] optional transaction value field filling.
    # @return [Object] returns the result of the transaction.
    def transact(contract, function, *args, **kwargs)
      gas_limit = if kwargs[:gas_limit]
          kwargs[:gas_limit]
        else
          Tx.estimate_intrinsic_gas(contract.bin)
        end
      fun = contract.functions.select { |func| func.name == function }[0]
      params = {
        value: kwargs[:tx_value] || 0,
        gas_limit: gas_limit,
        chain_id: chain_id,
        to: kwargs[:address] || contract.address,
        data: call_payload(fun, args),
      }
      send_transaction(params, kwargs[:legacy], kwargs[:sender_key], kwargs[:nonce])
    end

    # Executes a contract function with a transaction and waits for it
    # to be mined (transactional contract read/write).
    #
    # See {#transact} for params and overloads.
    #
    # @raise [Client::ContractExecutionError] if the execution fails.
    # @return [Object] returns the result of the transaction.
    def transact_and_wait(contract, function, *args, **kwargs)
      begin
        hash = wait_for_tx(transact(contract, function, *args, **kwargs))
        return hash if tx_succeeded? hash
      rescue IOError => e
        raise ContractExecutionError, e
      end
    end

    # Provides an interface to call `isValidSignature` as per EIP-1271 on a given
    # smart contract to verify the given hash and signature matching the magic
    # value.
    #
    # @param contract [Eth::Contract] a deployed contract implementing EIP-1271.
    # @param hash [String] the message hash to be checked against the signature.
    # @param signature [String] the signature to be recovered by the contract.
    # @param magic [String] the expected magic value (defaults to `1626ba7e`).
    # @return [Boolean] true if magic matches and signature is valid.
    # @raise [ArgumentError] in case the contract cannot be called yet.
    def is_valid_signature(contract, hash, signature, magic = "1626ba7e")
      raise ArgumentError, "Contract not deployed yet." if contract.address.nil?
      hash = Util.hex_to_bin hash if Util.hex? hash
      signature = Util.hex_to_bin signature if Util.hex? signature
      magic = Util.hex_to_bin magic if Util.hex? magic
      result = call(contract, "isValidSignature", hash, signature)
      result === magic
    end

    # Gives control over resetting the RPC request ID back to zero.
    # Usually not needed.
    #
    # @return [Integer] 0
    def reset_id
      @id = 0
    end

    # Checks whether a transaction is mined or not.
    #
    # @param hash [String] the transaction hash.
    # @return [Boolean] true if included in a block.
    def tx_mined?(hash)
      mined_tx = eth_get_transaction_by_hash hash
      !mined_tx.nil? && !mined_tx["result"].nil? && !mined_tx["result"]["blockNumber"].nil?
    end

    # Checks whether a contract transaction succeeded or not.
    #
    # @param hash [String] the transaction hash.
    # @return [Boolean] true if status is success.
    def tx_succeeded?(hash)
      tx_receipt = eth_get_transaction_receipt(hash)
      !tx_receipt.nil? && !tx_receipt["result"].nil? && tx_receipt["result"]["status"] == "0x1"
    end

    # Waits for an transaction to be mined by the connected chain.
    #
    # @param hash [String] the transaction hash.
    # @return [String] the transaction hash once the transaction is mined.
    # @raise [Timeout::Error] if it's not mined within 5 minutes.
    def wait_for_tx(hash)
      start_time = Time.now
      timeout = 300
      retry_rate = 0.1
      loop do
        raise Timeout::Error if ((Time.now - start_time) > timeout)
        return hash if tx_mined? hash
        sleep retry_rate
      end
    end

    # Metafunction to provide all known RPC commands defined in
    # {Eth::Api} as snake_case methods to the {Eth::Client} classes.
    Api::COMMANDS.each do |cmd|
      method_name = cmd.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      define_method method_name do |*args|
        send_command cmd, args
      end
    end

    private

    # Allows to determine if we work with a local connectoin
    def local?
      if self.instance_of? Eth::Client::Ipc
        true
      elsif self.host === "127.0.0.1" || self.host === "localhost"
        true
      else
        false
      end
    end

    # Prepares a transaction to be send for the given params.
    def send_transaction(params, legacy, key, nonce)
      if legacy
        params.merge!({ gas_price: max_fee_per_gas })
      else
        params.merge!({
          priority_fee: max_priority_fee_per_gas,
          max_gas_fee: max_fee_per_gas,
        })
      end
      unless key.nil?

        # use the provided key as sender and signer
        params.merge!({
          from: key.address,
          nonce: nonce || get_nonce(key.address),
        })
        tx = Eth::Tx.new(params)
        tx.sign key
        eth_send_raw_transaction(tx.hex)["result"]
      else

        # do not allow accessing accounts on remote connections
        raise ArgumentError, "The default account is not available on remote connections, please provide a :sender_key!" unless local?

        # use the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: nonce || get_nonce(default_account),
        })
        eth_send_transaction(params)["result"]
      end
    end

    # Non-transactional function call called from call().
    # @see https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_call
    def call_raw(contract, func, *args, **kwargs)
      params = {
        data: call_payload(func, args),
        to: kwargs[:address] || contract.address,
        from: kwargs[:from],
      }.compact

      raw_result = eth_call(params)["result"]
      types = func.outputs.map { |i| i.type }
      return nil if raw_result == "0x"
      Eth::Abi.decode(types, raw_result)
    end

    # Encodes function call payloads.
    def call_payload(fun, args)
      types = fun.inputs.map(&:parsed_type)
      encoded_str = Util.bin_to_hex(Eth::Abi.encode(types, args))
      Util.prefix_hex(fun.signature + (encoded_str.empty? ? "0" * 64 : encoded_str))
    end

    # Encodes constructor params
    def encode_constructor_params(contract, args)
      types = contract.constructor_inputs.map { |input| input.type }
      Util.bin_to_hex(Eth::Abi.encode(types, args))
    end

    # Prepares parameters and sends the command to the client.
    def send_command(command, args)
      @block_number ||= "latest"
      args << block_number if ["eth_getBalance", "eth_call"].include? command
      payload = {
        jsonrpc: "2.0",
        method: command,
        params: marshal(args),
        id: next_id,
      }
      output = JSON.parse(send_request(payload.to_json))
      raise IOError, output["error"]["message"] unless output["error"].nil?
      output
    end

    # Increments the request id.
    def next_id
      @id += 1
    end

    # expects Hash object
    def camelize!(params)
      params.transform_keys! do |k|
        k = k.to_s.split(/_/).map(&:capitalize).join
        k[0] = k[0].downcase
        k.to_sym
      end
    end

    # Recursively marshals all request parameters.
    def marshal(params)
      params = params.dup
      if params.is_a? Array
        params.map! { |param| marshal(param) }
      elsif params.is_a? Hash
        params = camelize!(params)
        params.transform_values! { |param| marshal(param) }
      elsif params.is_a? Numeric
        Util.prefix_hex "#{params.to_i.to_s(16)}"
      elsif params.is_a? Address
        params.to_s
      elsif Util.hex? params
        Util.prefix_hex params
      else
        params
      end
    end
  end
end

# Load the client/* libraries
require "eth/client/http"
require "eth/client/ipc"
