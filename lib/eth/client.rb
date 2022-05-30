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

  # Provides the {Eth::Client} super-class to connect to Ethereum
  # network's RPC-API endpoints (IPC or HTTP).
  class Client

    # The client's RPC-request ID starting at 0.
    attr_reader :id

    # The connected network's chain ID.
    attr_reader :chain_id

    # The connected network's client coinbase.
    attr_accessor :default_account

    # The default transaction max priority fee per gas in Wei.
    attr_accessor :max_priority_fee_per_gas

    # The default transaction max fee per gas in Wei.
    attr_accessor :max_fee_per_gas

    # The default gas limit for the transaction.
    attr_accessor :gas_limit

    # Creates a new RPC-Client, either by providing an HTTP/S host or
    # an IPC path.
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
      @max_priority_fee_per_gas = 0
      @max_fee_per_gas = Tx::DEFAULT_GAS_PRICE
      @gas_limit = Tx::DEFAULT_GAS_LIMIT
    end

    # Gets the default account (coinbase) of the connected client.
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
    # Uses `eth_coinbase` and external signer if no  sender key is
    # provided.
    #
    # @param destination [Eth::Address] the destination address.
    # @param amount [Integer] the transfer amount in Wei.
    # @param sender_key [Eth::Key] the sender private key.
    # @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [String] the transaction hash.
    def transfer_and_wait(destination, amount, sender_key = nil, legacy = false)
      wait_for_tx(transfer(destination, amount, sender_key, legacy))
    end

    # Simply transfer Ether to an account without any call data or
    # access lists attached. Uses `eth_coinbase` and external signer
    # if no sender key is provided.
    #
    # @param destination [Eth::Address] the destination address.
    # @param amount [Integer] the transfer amount in Wei.
    # @param sender_key [Eth::Key] the sender private key.
    # @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [String] the transaction hash.
    def transfer(destination, amount, sender_key = nil, legacy = false)
      params = {
        value: amount,
        to: destination,
        gas_limit: gas_limit,
        chain_id: chain_id,
      }
      if legacy
        params.merge!({
          gas_price: max_fee_per_gas,
        })
      else
        params.merge!({
          priority_fee: max_priority_fee_per_gas,
          max_gas_fee: max_fee_per_gas,
        })
      end
      unless sender_key.nil?

        # use the provided key as sender and signer
        params.merge!({
          from: sender_key.address,
          nonce: get_nonce(sender_key.address),
        })
        tx = Eth::Tx.new(params)
        tx.sign sender_key
        return eth_send_raw_transaction(tx.hex)["result"]
      else

        # use the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: get_nonce(default_account),
        })
        return eth_send_transaction(params)["result"]
      end
    end

    # Deploys a contract and waits for it to be mined. Uses
    # `eth_coinbase` or external signer if no sender key is provided.
    #
    # @overload deploy(contract)
    #   @param contract [Eth::Contract] contracts to deploy.
    # @overload deploy(contract, *args, **kwargs)
    #   @param contract [Eth::Contract] contracts to deploy.
    #   *args Optional variable constructor parameter list
    #   **sender_key [Eth::Key] the sender private key.
    #   **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [String] the contract address.
    def deploy_and_wait(contract, *args, **kwargs)
      hash = wait_for_tx(deploy(contract, *args, **kwargs))
      addr = eth_get_transaction_receipt(hash)["result"]["contractAddress"]
      contract.address = Address.new(addr).to_s
    end

    # Deploys a contract. Uses `eth_coinbase` or external signer
    # if no sender key is provided.
    #
    # @overload deploy(contract)
    #   @param contract [Eth::Contract] contracts to deploy.
    # @overload deploy(contract, *args, **kwargs)
    #   @param contract [Eth::Contract] contracts to deploy.
    #   *args Optional variable constructor parameter list
    #   **sender_key [Eth::Key] the sender private key.
    #   **legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [String] the transaction hash.
    # @raise [ArgumentError] in case the contract does not have any source.
    def deploy(contract, *args, **kwargs)
      raise ArgumentError, "Cannot deploy contract without source or binary!" if contract.bin.nil?
      raise ArgumentError, "Missing contract constructor params!" if contract.constructor_inputs.length != args.length
      gas_limit = Tx.estimate_intrinsic_gas(contract.bin) + Tx::CREATE_GAS
      data = contract.bin
      unless args.empty?
        data += encode_constructor_params(contract, args)
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
          nonce: get_nonce(kwargs[:sender_key].address),
        })
        tx = Eth::Tx.new(params)
        tx.sign kwargs[:sender_key]
        return eth_send_raw_transaction(tx.hex)["result"]
      else
        # Uses the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: get_nonce(default_account),
        })
        return eth_send_transaction(params)["result"]
      end
    end

    # Calls a contract function without executing it
    # (non-transactional contract read).
    #
    # @overload call(contract, function_name)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    # @overload call(contract, function_name, value)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    #   @param value [Integer|String] function arguments.
    # @overload call(contract, function_name, value, sender_key, legacy)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    #   @param value [Integer|String] function arguments.
    #   @param sender_key [Eth::Key] the sender private key.
    #   @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [Object] returns the result of the call.
    def call(contract, function_name, *args, **kwargs)
      func = contract.functions.select { |func| func.name == function_name }[0]
      raise ArgumentError, "function_name does not exist!" if func.nil?
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
    # @overload transact(contract, function_name)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    # @overload transact(contract, function_name, value)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    #   @param value [Integer|String] function arguments.
    # @overload transact(contract, function_name, value, sender_key, legacy, address)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    #   @param value [Integer|String] function arguments.
    #   @param sender_key [Eth::Key] the sender private key.
    #   @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    #   @param address [String] contract address.
    # @return [Object] returns the result of the call.
    def transact(contract, function_name, *args, **kwargs)
      gas_limit = Tx.estimate_intrinsic_gas(contract.bin) + Tx::CREATE_GAS
      fun = contract.functions.select { |func| func.name == function_name }[0]
      params = {
        value: 0,
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
          nonce: get_nonce(kwargs[:sender_key].address),
        })
        tx = Eth::Tx.new(params)
        tx.sign kwargs[:sender_key]
        return eth_send_raw_transaction(tx.hex)["result"]
      else
        # use the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: get_nonce(default_account),
        })
        return eth_send_transaction(params)["result"]
      end
    end

    # Executes a contract function with a transaction and waits for it
    # to be mined (transactional contract read/write).
    #
    # @overload transact_and_wait(contract, function_name)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    # @overload transact_and_wait(contract, function_name, value)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    #   @param value [Integer|String] function arguments.
    # @overload transact_and_wait(contract, function_name, value, sender_key, legacy, address)
    #   @param contract [Eth::Contract] subject contract to call.
    #   @param function_name [String] method name to be called.
    #   @param value [Integer|String] function arguments.
    #   @param sender_key [Eth::Key] the sender private key.
    #   @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    #   @param address [String] contract address.
    # @return [Object] returns the result of the call.
    def transact_and_wait(contract, function_name, *args, **kwargs)
      wait_for_tx(transact(contract, function_name, *args, **kwargs))
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
      hash = Util.hex_to_bin hash if Util.is_hex? hash
      signature = Util.hex_to_bin signature if Util.is_hex? signature
      magic = Util.hex_to_bin magic if Util.is_hex? magic
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
    def is_mined_tx?(hash)
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
        return hash if is_mined_tx? hash
        sleep retry_rate
      end
    end

    # Metafunction to provide all known RPC commands defined in
    # Eth::Api as snake_case methods to the Eth::Client classes.
    Api::COMMANDS.each do |cmd|
      method_name = cmd.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      define_method method_name do |*args|
        send_command cmd, args
      end
    end

    private

    # Non-transactional function call called from call().
    def call_raw(contract, func, *args, **kwargs)
      gas_limit = Tx.estimate_intrinsic_gas(contract.bin) + Tx::CREATE_GAS
      params = {
        gas_limit: gas_limit,
        chain_id: chain_id,
        data: call_payload(func, args),
      }
      if kwargs[:address] || contract.address
        params.merge!({ to: kwargs[:address] || contract.address })
      end
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
          nonce: get_nonce(kwargs[:sender_key].address),
        })
        tx = Eth::Tx.new(params)
        tx.sign kwargs[:sender_key]
      end
      raw_result = eth_call(params)["result"]
      types = func.outputs.map { |i| i.type }
      return nil if raw_result == "0x"
      Eth::Abi.decode(types, raw_result)
    end

    # Encodes function call payloads.
    def call_payload(fun, args)
      types = fun.inputs.map { |i| i.type }
      encoded_str = Util.bin_to_hex(Eth::Abi.encode(types, args))
      "0x" + fun.signature + (encoded_str.empty? ? "0" * 64 : encoded_str)
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
      elsif Util.is_hex? params
        return Util.prefix_hex params
      else
        return params
      end
    end
  end
end

# Load the client/* libraries
require "eth/client/http"
require "eth/client/ipc"
