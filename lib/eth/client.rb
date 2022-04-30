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

    # Deploy contract and waits for it to be mined.
    # Uses `eth_coinbase` and external signer
    # if no sender key is provided.
    #
    # @param contract [Eth::Contract] contracts to deploy.
    # @param sender_key [Eth::Key] the sender private key.
    # @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [String] the transaction hash.
    def deploy_and_wait(contract, sender_key = nil, legacy = false)
      wait_for_tx(deploy(contract, sender_key, legacy))
    end

    # Deploy contract. Uses `eth_coinbase` and external signer
    # if no sender key is provided.
    #
    # @param contract [Eth::Contract] contracts to deploy.
    # @param sender_key [Eth::Key] the sender private key.
    # @param legacy [Boolean] enables legacy transactions (pre-EIP-1559).
    # @return [String] the transaction hash.
    def deploy(contract, sender_key = nil, legacy = false)
      gas_limit =  Tx.estimate_intrinsic_gas(contract.bin) - Tx::DEFAULT_GAS_LIMIT + 53000
      params = {
        value: 0,
        gas_limit: gas_limit,
        chain_id: chain_id,
        data: contract.bin
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

    def call_payload(fun, args)
      encoded_str = Eth::Contract::Encoder.new.encode_arguments(fun.inputs, args)
      "0x" + fun.signature + (encoded_str.empty? ? "0"*64 : encoded_str)
    end

    def call_args(fun, args)
      {to: @address, from: @sender, data: call_payload(fun, args)}
    end

    def call_raw(fun, sender_key = nil, legacy = false, args)
      params = call_args(fun, args) 
      params.merge!({
        gas_limit: gas_limit,
        chain_id: chain_id,
      })
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
      else
        # use the default account as sender and external signer
        params.merge!({
          from: default_account,
          nonce: get_nonce(default_account),
        })
      end
      raw_result = eth_call(params)["result"]
      output = Eth::Contract::Decoder.new.decode_arguments(fun.outputs, raw_result)
      return {data: call_payload(fun, args), raw: raw_result, formatted: output}
    end

    def call(contract, function_name, sender_key = nil, legacy = false, *args)
      func = contract.functions.select {|func| func.name == function_name }[0]
      raise ArgumentError, "function_name does not exist!" if func.nil?
      output = call_raw(func, nil, nil, args)[:formatted]
      if output.length == 1
        return output[0]
      else
        return output
      end
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
    # @return [String] the transactin hash once the transaction is mined.
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
