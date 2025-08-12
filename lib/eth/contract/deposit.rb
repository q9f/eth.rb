# Copyright (c) 2016-2025 The Ruby-Eth Contributors
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

  # Provides classes to access smart contracts
  module Contract

    # Provides Ethereum consensus deposit contract helpers
    module Deposit
      extend self
  
      # Default address of the deposit contract on mainnet
      DEFAULT_ADDRESS = Address.new("0x00000000219ab540356cBB839Cbe05303d7705Fa").freeze
  
      # Load deposit contract ABI
      ABI = JSON.parse(
        File.read(File.join(File.dirname(__FILE__), "../../abi/deposit_contract.json"))
      )
  
      # Returns a contract wrapper for the deposit contract
      #
      # @param address [String] address of the deposit contract
      # @return [Eth::Contract] contract instance
      def contract(address = DEFAULT_ADDRESS)
        Contract.from_abi(
          name: "DepositContract",
          address: address,
          abi: ABI,
        )
      end
  
      # Submits a deposit to the deposit contract
      #
      # @param client [Eth::Client] client used to submit the deposit
      # @param pubkey [String] BLS12-381 public key
      # @param withdrawal_credentials [String] withdrawal credentials
      # @param signature [String] BLS12-381 signature
      # @param deposit_data_root [String] deposit data root
      # @param value [Integer] amount to deposit in wei
      # @param address [String] deposit contract address
      # @param kwargs [Hash] additional transaction options
      # @return [Object] result of transaction submission
      def deposit(client, pubkey, withdrawal_credentials, signature, deposit_data_root, value:, address: DEFAULT_ADDRESS, **kwargs)
        client.transact(
          contract(address),
          "deposit",
          pubkey,
          withdrawal_credentials,
          signature,
          deposit_data_root,
          **kwargs.merge(tx_value: value),
        )
      end
  
      # Parses a DepositEvent log entry
      #
      # @param log [Hash] log entry as returned by RPC
      # @return [Hash] decoded event parameters with hex values
      def parse_deposit_event(log)
        evt = contract(log["address"]).events.find { |e| e.name == "DepositEvent" }
        values = evt.decode_params(log["topics"], log["data"])
        values = values.transform_keys(&:to_sym)
        values.transform_values { |v| Util.bin_to_prefixed_hex(v) }
      end
    end
  end
end
