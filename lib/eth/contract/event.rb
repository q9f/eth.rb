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

# -*- encoding : ascii-8bit -*-

module Eth
  # Provide classes for contract event.
  class Contract::Event
    # Constructor of the {Eth::Contract::Event} class.
    #
    # @param data [Hash] contract event data.
    def initialize(data)
      @data = data
    end

    # Returns the name of the event.
    #
    # @return [String] The event name.
    def name
      @data["name"]
    end

    # Returns the input types for the event.
    #
    # @return [Array<String>] An array of input type names.
    def input_types
      @input_types ||= @data["inputs"].map { |x| type_name(x) }
    end

    # Returns the names of input parameters.
    #
    # @return [Array<String>] An array of input parameter names.
    def inputs
      @inputs ||= @data["inputs"].map { |x| x["name"] }
    end

    # Returns the event signature string.
    #
    # @return [String] The event signature string, generated from ABI.
    def event_string
      @event_string ||= Abi::Event.signature(@data)
    end

    # Returns the Keccak-256 event signature hash.
    #
    # @return [String] The event signature hash in hexadecimal format.
    def signature
      @signature ||= Digest::Keccak.hexdigest(event_string, 256)
    end

    # Returns the Ethereum address associated with the event.
    #
    # @return [String, nil] The Ethereum address, or `nil` if not set.
    def address
      @address ||= nil
    end

    # Set the address of the smart contract
    #
    # @param address [String] contract address.
    def set_address(address)
      @address = address ? Eth::Address.new(address).address : nil
    end

    # Decodes event parameters from logs.
    #
    # @param topics [Array<String>] The list of log topics, including the event selector.
    # @param data [String] The log data containing non-indexed parameters.
    # @return [ActiveSupport::HashWithIndifferentAccess] A hash of decoded event parameters.
    def decode_params(topics, data = "0x")
      inputs = @data["inputs"]

      indexed_inputs, non_indexed_inputs = inputs.partition { _1["indexed"] }

      {
        **indexed_inputs.each_with_index.inject({}) do |result, (input, index)|
          result[input["name"]] = Eth::Abi.decode([input["type"]], topics[index + 1])[0]
          result
        end,
        **Hash[non_indexed_inputs.map { _1["name"] }.zip(
                 Eth::Abi.decode(non_indexed_inputs.map { |i| i["type"] }, data)
               )],
      }
    end

    private

    def type_name(x)
      case x["type"]
      when "tuple"
        "(#{x["components"].map { |c| type_name(c) }.join(",")})"
      else
        x["type"]
      end
    end
  end
end

# Provides the {Eth} module.
