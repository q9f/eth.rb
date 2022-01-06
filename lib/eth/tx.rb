# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     attr_reader :http
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "rlp"
require "konstructor"
require "eth/tx/eip1559"
require "eth/tx/eip2930"
require "eth/tx/legacy"

# Provides the `Eth` module.
module Eth

  # Provides the `Tx` module supporting various transaction types.
  module Tx
    extend self

    # The minimum transaction gas limit required for a value transfer.
    DEFAULT_LIMIT = 21_000

    # The maximum transaction gas limit is bound by the block gas limit.
    BLOCK_LIMIT = 25_000_000

    # The legacy transaction type is 0.
    TYPE_LEGACY = 0x00

    # The EIP-2930 transaction type is 1.
    TYPE_2930 = 0x01

    # The EIP-1559 transaction type is 2.
    TYPE_1559 = 0x02

    # Validates the common type-2 transaction fields such as nonce, priority
    # fee, gas fee, gas limit, amount, and access list.
    #
    # @param fields [Hash] the transaction fields.
    # @return [Hash] the validated transaction fields.
    # @raise [ArgumentError] if nonce is an invalid integer.
    # @raise [ArgumentError] if priority fee is invalid.
    # @raise [ArgumentError] if gas fee is invalid.
    # @raise [ArgumentError] if gas limit is invalid.
    # @raise [ArgumentError] if amount is invalid.
    # @raise [ArgumentError] if access list is invalid.
    def validate_params(fields)
      unless fields[:nonce] >= 0
        raise ArgumentError, "Invalid signer nonce #{fields[:nonce]}!"
      end
      unless fields[:priority_fee] >= 0
        raise ArgumentError, "Invalid gas priority fee #{fields[:priority_fee]}!"
      end
      unless fields[:max_gas_fee] >= 0
        raise ArgumentError, "Invalid max gas fee #{fields[:max_gas_fee]}!"
      end
      unless fields[:gas_limit] >= DEFAULT_LIMIT and fields[:gas_limit] <= BLOCK_LIMIT
        raise ArgumentError, "Invalid gas limit #{fields[:gas_limit]}!"
      end
      unless fields[:value] >= 0
        raise ArgumentError, "Invalid transaction value #{fields[:value]}!"
      end
      unless fields[:access_list].nil? or fields[:access_list].is_a? Array
        raise ArgumentError, "Invalid access list #{fields[:access_list]}!"
      end
      return fields
    end

    # Validates the common legacy transaction fields such as nonce, gas
    # price, gas limit, amount, and access list.
    #
    # @param fields [Hash] the transaction fields.
    # @return [Hash] the validated transaction fields.
    # @raise [ArgumentError] if nonce is an invalid integer.
    # @raise [ArgumentError] if gas price is invalid.
    # @raise [ArgumentError] if gas limit is invalid.
    # @raise [ArgumentError] if amount is invalid.
    # @raise [ArgumentError] if access list is invalid.
    def validate_legacy_params(fields)
      unless fields[:nonce] >= 0
        raise ArgumentError, "Invalid signer nonce #{fields[:nonce]}!"
      end
      unless fields[:gas_price] >= 0
        raise ArgumentError, "Invalid gas price #{fields[:gas_price]}!"
      end
      unless fields[:gas_limit] >= DEFAULT_LIMIT and fields[:gas_limit] <= BLOCK_LIMIT
        raise ArgumentError, "Invalid gas limit #{fields[:gas_limit]}!"
      end
      unless fields[:value] >= 0
        raise ArgumentError, "Invalid transaction value #{fields[:value]}!"
      end
      unless fields[:access_list].nil? or fields[:access_list].is_a? Array
        raise ArgumentError, "Invalid access list #{fields[:access_list]}!"
      end
      return fields
    end

    # Populates the transaction chain id field with a serializable default
    # value (1) in case it is undefined.
    #
    # @param id [Integer] the transaction chain id.
    # @return [Integer] the sanitized transaction chain id.
    def sanitize_chain(id)
      id = Chain::ETHEREUM if id.nil?
      return id
    end

    # Populates the transaction destination address with a serializable
    # empty value in case it is undefined; also ensures the address is
    # checksummed but not prefixed for consistency.
    #
    # @param addr [String] the transaction destination address.
    # @return [String] the sanitized transaction destination address.
    def sanitize_address(addr)
      addr = "" if addr.nil?
      if addr.is_a? String and !addr.empty?
        addr = Address.new(addr).to_s
        addr = Util.remove_hex_prefix addr
      end
      return addr
    end

    # Populates the transaction value field with a serializable empty value
    # in case it is undefined.
    #
    # @param val [Integer] the transaction value.
    # @return [Integer] the sanitized transaction value.
    def sanitize_amount(val)
      val = 0 if val.nil?
      return val
    end

    # Populates the transaction payload field with a serializable empty value
    # in case it is undefined; also ensures the data is binary not hex.
    #
    # @param data [String] the transaction payload data.
    # @return [String] the sanitized transaction payload data.
    def sanitize_data(data)
      data = "" if data.nil?

      # ensure payload to be binary if it's hex, otherwise we'll treat it raw
      data = Util.hex_to_bin data if Util.is_hex? data
      return data
    end

    # Populates the transaction access list field with a serializable empty
    # array in case it is undefined; also ensures the nested data is binary
    # not hex.
    #
    # @param list [Array] the transaction access list.
    # @return [Array] the sanitized transaction access list.
    def sanitize_list(list)
      list = [] if list.nil?
      list.each_with_index do |value, index|
        if value.is_a? Array

          # recursively check the entire array
          list[index] = sanitize_list value
        elsif Util.is_hex? value

          # only modify if we find a hex value
          list[index] = Util.hex_to_bin value
        end
      end
      return list
    end

    # Allows to check wether a transaction is signed already.
    #
    # @return [Bool] true if transaction is already signed.
    def is_signed?(tx)
      !tx.signature_r.nil? and tx.signature_r != 0 and
      !tx.signature_s.nil? and tx.signature_s != 0
    end
  end
end
