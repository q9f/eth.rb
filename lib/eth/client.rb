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

# Provides the `Eth` module.
module Eth
  class Client
    attr_reader :id
    attr_reader :chain_id
    attr_accessor :default_account
    attr_accessor :max_priority_fee_per_gas
    attr_accessor :max_fee_per_gas
    attr_accessor :gas_limit

    def self.create(host)
      return Client::Ipc.new host if host.end_with? ".ipc"
      return Client::Http.new host if host.start_with? "http"
      raise ArgumentError, "Unable to detect client type!"
    end

    def initialize(_)
      @id = 0
      @max_priority_fee_per_gas = 0
      @max_fee_per_gas = Tx::DEFAULT_GAS_PRICE
      @gas_limit = Tx::DEFAULT_GAS_LIMIT
    end

    def default_account
      @default_account ||= Address.new eth_coinbase["result"]
    end

    def chain_id
      @chain_id ||= eth_chain_id["result"].to_i 16
    end

    def get_balance(address)
      eth_get_balance(address.to_s)["result"].to_i 16
    end

    def get_nonce(address)
      eth_get_transaction_count(address.to_s, "pending")["result"].to_i 16
    end

    def transfer_and_wait(key, address, amount)
      wait_for(transfer(key, address, amount))
    end

    def transfer(key, address, amount)
      Eth.configure { |c| c.chain_id = net_version["result"].to_i }
      args = {
        from: key.address,
        to: address,
        value: amount,
        nonce: get_nonce(key.address),
        gas_limit: gas_limit,
        priority_fee: max_priority_fee_per_gas,
        max_gas_fee: max_fee_per_gas,
        chain_id: chain_id,
      }
      tx = Eth::Tx.new(args)
      tx.sign key
      eth_send_raw_transaction(tx.hex)["result"]
    end

    def reset_id
      @id = 0
    end

    def is_mined?(tx)
      mined_tx = eth_get_transaction_by_hash tx.hash
      !mined_tx.nil? && !mined_tx["result"].nil? && mined_tx["result"]["blockNumber"].present?
    end

    def wait_for(tx)
      start_time = Time.now
      timeout = 300.seconds
      retry_rate = 5.seconds
      loop do
        raise Timeout::Error if ((Time.now - start_time) > timeout)
        return tx.hash if is_mined? tx
        sleep retry_rate
      end
    end

    Api::COMMANDS.each do |cmd|
      method_name = cmd.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      define_method method_name do |*args|
        send_command cmd, args
      end
    end

    private

    def send_command(command, args)
      args << "latest" if ["eth_getBalance", "eth_call"].include?(command)
      payload = {
        jsonrpc: "2.0",
        method: command,
        params: sanitize_params(args),
        id: next_id,
      }
      output = JSON.parse(send(payload.to_json))
      raise IOError, output["error"]["message"] unless output["error"].nil?
      return output
    end

    def next_id
      @id += 1
    end

    def sanitize_params(params)
      params.map(&method(:int_to_hex))
    end

    def int_to_hex(p)
      p.is_a?(Integer) ? Util.prefix_hex("#{p.to_s(16)}") : p
    end
  end
end
