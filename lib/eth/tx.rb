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

require "konstructor"

require "eth/chain"
require "eth/tx/eip1559"
require "eth/tx/eip2930"
require "eth/tx/legacy"
require "eth/unit"

# Provides the {Eth} module.
module Eth

  # Provides the `Tx` module supporting various transaction types.
  module Tx
    extend self

    # Provides a special transaction error if transaction type is unknown.
    class TransactionTypeError < TypeError; end

    # Provides an decoder error if transaction cannot be decoded.
    class DecoderError < StandardError; end

    # Provides a parameter error if parameter types are invalid.
    class ParameterError < TypeError; end

    # The minimum transaction gas limit required for a value transfer.
    DEFAULT_GAS_LIMIT = 21_000.freeze

    # The "default" transaction gas price of 20 GWei. Do not use.
    DEFAULT_GAS_PRICE = (20 * Unit::GWEI).freeze

    # The calldata gas cost of a non-zero byte as per EIP-2028.
    COST_NON_ZERO_BYTE = 16.freeze

    # The calldata gas cost of a zero byte.
    COST_ZERO_BYTE = 4.freeze

    # The access list gas cost of a storage key as per EIP-2930.
    COST_STORAGE_KEY = 1_900.freeze

    # The access list gas cost of an address as per EIP-2930.
    COST_ADDRESS = 2_400.freeze

    # The maximum transaction gas limit is bound by the block gas limit.
    BLOCK_GAS_LIMIT = 25_000_000.freeze

    # The legacy transaction type is 0.
    TYPE_LEGACY = 0x00.freeze

    # The EIP-2930 transaction type is 1.
    TYPE_2930 = 0x01.freeze

    # The EIP-1559 transaction type is 2.
    TYPE_1559 = 0x02.freeze

    # The zero byte is 0x00.
    ZERO_BYTE = "\x00".freeze

    # Smart contract transaction gas cost
    CREATE_GAS = 32_000.freeze

    # Creates a new transaction of any type for given parameters and chain ID.
    # Required parameters are (optional in brackets):
    # - EIP-1559: chain_id, nonce, priority_fee, max_gas_fee, gas_limit(, from, to,
    #   value, data, access_list)
    # - EIP-2930: chain_id, nonce, gas_price, gas_limit, access_list(, from, to,
    #   value, data)
    # - Legacy: nonce, gas_price, gas_limit(, from, to, value, data)
    #
    # @param params [Hash] all necessary transaction fields.
    # @param chain_id [Integer] the EIP-155 Chain ID (legacy transactions only).
    def new(params, chain_id = Chain::ETHEREUM)

      # if we deal with max gas fee parameter, attempt EIP-1559
      unless params[:max_gas_fee].nil?
        params[:chain_id] = chain_id if params[:chain_id].nil?
        return Tx::Eip1559.new params
      end

      # if we deal with access list parameter, attempt EIP-2930
      unless params[:access_list].nil?
        params[:chain_id] = chain_id if params[:chain_id].nil?
        return Tx::Eip2930.new params
      end

      # if nothing else, go with legacy transactions
      chain_id = params[:chain_id] if !params[:chain_id].nil? and params[:chain_id] != chain_id
      return Tx::Legacy.new params, chain_id
    end

    # Decodes a transaction hex of any known type (2, 1, or legacy).
    #
    # @param hex [String] the raw transaction hex-string.
    # @return [Eth::Tx] transaction payload.
    # @raise [TransactionTypeError] if the transaction type is unknown.
    def decode(hex)
      hex = Util.remove_hex_prefix hex
      type = hex[0, 2].to_i(16)
      case type
      when TYPE_1559

        # EIP-1559 transaction (type 2)
        return Tx::Eip1559.decode hex
      when TYPE_2930

        # EIP-2930 transaction (type 1)
        return Tx::Eip2930.decode hex
      else

        # Legacy transaction if first byte is RLP (>= 192)
        if type >= 0xc0
          return Tx::Legacy.decode hex
        else
          raise TransactionTypeError, "Cannot decode unknown transaction type #{type}!"
        end
      end
    end

    # Creates an unsigned copy of any transaction object.
    #
    # @param tx [Eth::Tx] any transaction payload.
    # @return [Eth::Tx] an unsigned transaction payload of the same type.
    # @raise [TransactionTypeError] if the transaction type is unknown.
    def unsigned_copy(tx)
      case tx.type
      when TYPE_1559

        # EIP-1559 transaction (type 2)
        return Tx::Eip1559.unsigned_copy tx
      when TYPE_2930

        # EIP-2930 transaction (type 1)
        return Tx::Eip2930.unsigned_copy tx
      when TYPE_LEGACY

        # Legacy transaction ("type 0")
        return Tx::Legacy.unsigned_copy tx
      end
      raise TransactionTypeError, "Cannot copy unknown transaction type #{tx.type}!"
    end

    # Estimates intrinsic gas for provided call data (EIP-2028) and
    # access lists (EIP-2930).
    #
    # @param data [String] the call data.
    # @param list [Array] the access list.
    # @return [Integer] the estimated intrinsic gas cost.
    def estimate_intrinsic_gas(data = "", list = [])
      gas = DEFAULT_GAS_LIMIT
      unless data.nil? or data.empty?
        data = Util.hex_to_bin data if Util.is_hex? data

        # count zero bytes
        zero = data.count ZERO_BYTE
        gas += zero * COST_ZERO_BYTE

        # count non-zero bytes
        none = data.size - zero
        gas += none * COST_NON_ZERO_BYTE
      end
      unless list.nil? or list.empty?
        list.each do |entry|

          # count addresses
          gas += COST_ADDRESS

          entry.last.each do |key|

            # count storage keys
            gas += COST_STORAGE_KEY
          end
        end
      end
      return gas
    end

    # Validates the common transaction fields such as nonce, gas limit,
    # amount, and access list.
    #
    # @param fields [Hash] the transaction fields.
    # @return [Hash] the validated transaction fields.
    # @raise [ParameterError] if nonce is an invalid integer.
    # @raise [ParameterError] if gas limit is invalid.
    # @raise [ParameterError] if amount is invalid.
    # @raise [ParameterError] if access list is invalid.
    def validate_params(fields)
      if fields[:nonce].nil? or fields[:nonce] < 0
        raise ParameterError, "Invalid signer nonce #{fields[:nonce]}!"
      end
      if fields[:gas_limit].nil? or fields[:gas_limit] < DEFAULT_GAS_LIMIT or fields[:gas_limit] > BLOCK_GAS_LIMIT
        raise ParameterError, "Invalid gas limit #{fields[:gas_limit]}!"
      end
      unless fields[:value] >= 0
        raise ParameterError, "Invalid transaction value #{fields[:value]}!"
      end
      unless fields[:access_list].nil? or fields[:access_list].is_a? Array
        raise ParameterError, "Invalid access list #{fields[:access_list]}!"
      end
      return fields
    end

    # Validates the common type-2 transaction fields such as priority
    # fee and max gas fee.
    #
    # @param fields [Hash] the transaction fields.
    # @return [Hash] the validated transaction fields.
    # @raise [ParameterError] if priority fee is invalid.
    # @raise [ParameterError] if max gas fee is invalid.
    def validate_eip1559_params(fields)
      if fields[:priority_fee].nil? or fields[:priority_fee] < 0
        raise ParameterError, "Invalid gas priority fee #{fields[:priority_fee]}!"
      end
      if fields[:max_gas_fee].nil? or fields[:max_gas_fee] < 0
        raise ParameterError, "Invalid max gas fee #{fields[:max_gas_fee]}!"
      end
      return fields
    end

    # Validates the common legacy transaction fields such as gas price.
    #
    # @param fields [Hash] the transaction fields.
    # @return [Hash] the validated transaction fields.
    # @raise [ParameterError] if gas price is invalid.
    def validate_legacy_params(fields)
      if fields[:gas_price].nil? or fields[:gas_price] < 0
        raise ParameterError, "Invalid gas price #{fields[:gas_price]}!"
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
