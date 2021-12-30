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

require "eth/client/http"

# Provides the `Eth` module.
module Eth
  class Client
    DEFAULT_GAS_LIMIT = 8_000_000
    DEFAULT_GAS_PRICE = 42 * Eth::Unit::GWEI

    # ref https://github.com/ethereum/execution-apis
    # ref https://playground.open-rpc.org/?schemaUrl=https://raw.githubusercontent.com/ethereum/eth1.0-apis/assembled-spec/openrpc.json&uiSchema%5BappBar%5D%5Bui:splitView%5D=false&uiSchema%5BappBar%5D%5Bui:input%5D=false&uiSchema%5BappBar%5D%5Bui:examplesDropdown%5D=false
    RPC_COMMANDS = [
      "eth_accounts",
      "eth_blockNumber",
      "eth_call",
      "eth_coinbase",
      "eth_estimateGas",
      "eth_feeHistory",
      "eth_gasPrice",
      "eth_getBalance",
      "eth_getBlockByHash",
      "eth_getBlockByNumber",
      "eth_getBlockTransactionCountByHash",
      "eth_getBlockTransactionCountByNumber",
      "eth_getCode",
      "eth_getFilterChanges",
      "eth_getFilterLogs",
      "eth_getLogs",
      "eth_getStorageAt",
      "eth_getTransactionByBlockHashAndIndex",
      "eth_getTransactionByBlockNumberAndIndex",
      "eth_getTransactionByHash",
      "eth_getTransactionCount",
      "eth_getTransactionReceipt",
      "eth_getUncleCountByBlockHash",
      "eth_getUncleCountByBlockNumber",
      "eth_getWork",
      "eth_hashrate",
      "eth_mining",
      "eth_newBlockFilter",
      "eth_newFilter",
      "eth_newPendingTransactionFilter",
      "eth_protocolVersion",
      "eth_sendRawTransaction",
      "eth_sendTransaction",
      "eth_sign",
      "eth_signTransaction",
      "eth_submitHashrate",
      "eth_submitWork",
      "eth_syncing",
      "eth_uninstallFilter",
    ]

    attr_accessor :command
    attr_accessor :id
    # attr_accessor :log
    # attr_accessor :logger
    attr_accessor :default_account
    attr_accessor :gas_price
    attr_accessor :gas_limit

    def initialize(log = false)
      @id = 0
      # @log = log
      @batch = nil
      # @formatter = Ethereum::Formatter.new
      @gas_price = DEFAULT_GAS_PRICE
      @gas_limit = DEFAULT_GAS_LIMIT
      # if @log == true
      #   @logger = Logger.new("/tmp/ruby_eth_client.log")
      # end
    end

    def self.create(host_or_ipcpath, log = false)
      return IpcClient.new(host_or_ipcpath, log) if host_or_ipcpath.end_with? ".ipc"
      return HttpClient.new(host_or_ipcpath, log) if host_or_ipcpath.start_with? "http"
      raise ArgumentError, "Unable to detect client type"
    end

    def batch
      @batch = []

      yield
      result = send_batch(@batch)

      @batch = nil
      reset_id

      return result
    end

    def get_id
      @id += 1
      return @id
    end

    def reset_id
      @id = 0
    end

    def default_account
      @default_account ||= eth_accounts["result"][0]
    end

    def int_to_hex(p)
      p.is_a?(Integer) ? "0x#{p.to_s(16)}" : p
    end

    def encode_params(params)
      params.map(&method(:int_to_hex))
    end

    def get_balance(address)
      eth_get_balance(address)["result"].to_i(16)
    end

    def get_chain
      @net_version ||= net_version["result"].to_i
    end

    def get_nonce(address)
      eth_get_transaction_count(address, "pending")["result"].to_i(16)
    end

    def transfer_to(address, amount)
      eth_send_transaction({ to: address, value: int_to_hex(amount) })
    end

    def transfer_to_and_wait(address, amount)
      wait_for(transfer_to(address, amount)["result"])
    end

    def transfer(key, address, amount)
      Eth.configure { |c| c.chain_id = net_version["result"].to_i }
      args = {
        from: key.address,
        to: address,
        value: amount,
        data: "",
        nonce: get_nonce(key.address),
        gas_limit: gas_limit,
        gas_price: gas_price,
      }
      tx = Eth::Tx.new(args)
      tx.sign key
      eth_send_raw_transaction(tx.hex)["result"]
    end

    def transfer_and_wait(key, address, amount)
      return wait_for(transfer(key, address, amount))
    end

    def wait_for(tx)
      transaction = Ethereum::Transaction.new(tx, self, "", [])
      transaction.wait_for_miner
      return transaction
    end

    def send_command(command, args)
      if ["eth_getBalance", "eth_call"].include?(command)
        args << "latest"
      end

      payload = { jsonrpc: "2.0", method: command, params: encode_params(args), id: get_id }
      # @logger.info("Sending #{payload.to_json}") if @log
      if @batch
        @batch << payload
        return true
      else
        output = JSON.parse(send_single(payload.to_json))
        # @logger.info("Received #{output.to_json}") if @log
        reset_id
        raise IOError, output["error"]["message"] if output["error"]
        return output
      end
    end

    RPC_COMMANDS.each do |rpc_command|
      method_name = rpc_command.underscore
      define_method method_name do |*args|
        send_command(rpc_command, args)
      end
    end
  end
end
