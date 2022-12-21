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

    # The default gas limit for the transaction, defaults to {Tx::DEFAULT_GAS_LIMIT}.
    attr_accessor :gas_limit

    # Creates a new RPC-Client, either by providing an HTTP/S host or
    # an IPC path. Supports basic authentication with username and password.
    #
    # **Note**, this sets the folling gas defaults: {Tx::DEFAULT_PRIORITY_FEE},
    # {Tx::DEFAULT_GAS_PRICE}, and {Tx::DEFAULT_GAS_LIMIT}. Use
    # {#max_priority_fee_per_gas}, {#max_fee_per_gas}, and {#gas_limit} to set
    # custom values prior to submitting transactions.
    #
    # @param host [String] either an HTTP/S host or an IPC path.
    # @return [Eth::Client::Ipc] an IPC client.
    # @return [Eth::Client::HttpAuth] an HTTP client with basic authentication.
    # @return [Eth::Client::Http] an HTTP client.
    # @raise [ArgumentError] in case it cannot determine the client type.
    def self.create(host)
      return Client::Ipc.new host if host.end_with? ".ipc"
      return Client::HttpAuth.new host if Regexp.new(":.*@.*:", Regexp::IGNORECASE).match host
      return Client::Http.new host if host.start_with? "http"
      raise ArgumentError, "Unable to detect client type!"
    end

    # Constructor for the {Eth::Client} super-class. Should not be used;
    # use {Client.create} intead.
    def initialize(_)
      @id = 0
      @max_priority_fee_per_gas = Tx::DEFAULT_PRIORITY_FEE
      @max_fee_per_gas = Tx::DEFAULT_GAS_PRICE
      @gas_limit = Tx::DEFAULT_GAS_LIMIT
    end

    # Gets the default account (coinbase) of the connected client.
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts.
    #
    # @return [Eth::Address] the coinbase account address.
    def default_account
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
    # any accounts. Provide a `sender_key` if you experience issues.
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
        gas_limit: gas_limit,
        chain_id: chain_id,
      }
      if kwargs[:legacy]
        params.merge!({
          gas_price: max_fee_per_gas,
        })
      else
        params.merge!({
          priority_fee: max_priority_fee_per_gas,
          max_gas_fee: max_fee_per_gas,
        })
      end
      unless kwargs[:sender_key].nil?

        # use the provided key as sender and signer
        params.merge!({
          from: kwargs[:sender_key].address,
          nonce: kwargs[:nonce] || get_nonce(kwargs[:sender_key].address),
        })
        tx = Eth::Tx.new(params)
        tx.sign kwargs[:sender_key]
        return eth_send_raw_transaction(tx.hex)["result"]
      else

        # use the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: kwargs[:nonce] || get_nonce(default_account),
        })
        return eth_send_transaction(params)["result"]
      end
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
    # any accounts. Provide a `sender_key` if you experience issues.
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
      if kwargs[:legacy]
        params.merge!({
          gas_price: max_fee_per_gas,
        })
      else
        params.merge!({
          priority_fee: max_priority_fee_per_gas,
          max_gas_fee: max_fee_per_gas,
        })
      end
      unless kwargs[:sender_key].nil?
        # Uses the provided key as sender and signer
        params.merge!({
          from: kwargs[:sender_key].address,
          nonce: kwargs[:nonce] || get_nonce(kwargs[:sender_key].address),
        })
        tx = Eth::Tx.new(params)
        tx.sign kwargs[:sender_key]
        return eth_send_raw_transaction(tx.hex)["result"]
      else
        # Uses the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: kwargs[:nonce] || get_nonce(default_account),
        })
        return eth_send_transaction(params)["result"]
      end
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
    #   @param **gas_limit [Integer] optional gas limit override for deploying the contract.
    # @return [Object] returns the result of the call.
    def call(contract, function, *args, **kwargs)
      func = contract.functions.select { |func| func.name == function }[0]
      raise ArgumentError, "this function does not exist!" if func.nil?
      output = call_raw(contract, func, *args, **kwargs)
      if output&.length == 1
        return output[0]
      else
        return output
      end
    end

    # Executes a contract function with a transaction (transactional
    # contract read/write).
    #
    # **Note**, that many remote providers (e.g., Infura) do not provide
    # any accounts. Provide a `sender_key` if you experience issues.
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
    #   @param **gas_limit [Integer] optional gas limit override for deploying the contract.
    #   @param **nonce [Integer] optional specific nonce for transaction.
    #   @param **tx_value [Integer] optional transaction value field filling.
    # @return [Object] returns the result of the transaction.
    def transact(contract, function, *args, **kwargs)
      gas_limit = if kwargs[:gas_limit]
          kwargs[:gas_limit]
        else
          Tx.estimate_intrinsic_gas(contract.bin) + Tx::CREATE_GAS
        end
      fun = contract.functions.select { |func| func.name == function }[0]
      params = {
        value: kwargs[:tx_value] || 0,
        gas_limit: gas_limit,
        chain_id: chain_id,
        to: kwargs[:address] || contract.address,
        data: call_payload(fun, args),
      }
      if kwargs[:legacy]
        params.merge!({
          gas_price: max_fee_per_gas,
        })
      else
        params.merge!({
          priority_fee: max_priority_fee_per_gas,
          max_gas_fee: max_fee_per_gas,
        })
      end
      unless kwargs[:sender_key].nil?
        # use the provided key as sender and signer
        params.merge!({
          from: kwargs[:sender_key].address,
          nonce: kwargs[:nonce] || get_nonce(kwargs[:sender_key].address),
        })
        tx = Eth::Tx.new(params)
        tx.sign kwargs[:sender_key]
        return eth_send_raw_transaction(tx.hex)["result"]
      else
        # use the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: kwargs[:nonce] || get_nonce(default_account),
        })
        return eth_send_transaction(params)["result"]
      end
    end

    # Executes a contract function with a transaction and waits for it
    # to be mined (transactional contract read/write).
    #
    # See {#transact} for params and overloads.
    #
    # @return [Object] returns the result of the transaction.
    def transact_and_wait(contract, function, *args, **kwargs)
      wait_for_tx(transact(contract, function, *args, **kwargs))
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
      return result === magic
    end

    # Gives control over resetting the RPC request ID back to zero.
    # Usually not needed.
    #
    # @return [Integer] 0
    def reset_id
      @id = 0
    end

    # Checkes wether a transaction is mined or not.
    #
    # @param hash [String] the transaction hash.
    # @return [Boolean] true if included in a block.
    def mined?(hash)
      mined_tx = eth_get_transaction_by_hash hash
      !mined_tx.nil? && !mined_tx["result"].nil? && !mined_tx["result"]["blockNumber"].nil?
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
        return hash if mined? hash
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
      types = fun.inputs.map { |i| i.type }
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
      args << "latest" if ["eth_getBalance", "eth_call"].include? command
      payload = {
        jsonrpc: "2.0",
        method: command,
        params: marshal(args),
        id: next_id,
      }
      output = JSON.parse(send(payload.to_json))
      raise IOError, output["error"]["message"] unless output["error"].nil?
      return output
    end

    # Increments the request id.
    def next_id
      @id += 1
    end

    # Recursively marshals all request parameters.
    def marshal(params)
      if params.is_a? Array
        return params.map! { |param| marshal(param) }
      elsif params.is_a? Hash
        return params.transform_values! { |param| marshal(param) }
      elsif params.is_a? Numeric
        return Util.prefix_hex "#{params.to_i.to_s(16)}"
      elsif params.is_a? Address
        return params.to_s
      elsif Util.hex? params
        return Util.prefix_hex params
      else
        return params
      end
    end
  end
end

# Load the client/* libraries
require "eth/client/http"
require "eth/client/http_auth"
require "eth/client/ipc"
