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

# Provides the {Eth} module.
module Eth
  # Provide classes for contract custom errors.
  class Contract::Error
    attr_accessor :name, :inputs, :signature, :error_string

    # Constructor of the {Eth::Contract::Error} class.
    #
    # @param data [Hash] contract abi data for the error.
    def initialize(data)
      @name = data["name"]
      @inputs = data.fetch("inputs", []).map do |input|
        Eth::Contract::FunctionInput.new(input)
      end
      @error_string = self.class.calc_signature(@name, @inputs)
      @signature = self.class.encoded_error_signature(@error_string)
    end

    # Creates error strings.
    #
    # @param name [String] error name.
    # @param inputs [Array<Eth::Contract::FunctionInput>] error input class list.
    # @return [String] error string.
    def self.calc_signature(name, inputs)
      "#{name}(#{inputs.map { |x| x.parsed_type.to_s }.join(",")})"
    end

    # Encodes an error signature.
    #
    # @param signature [String] error signature.
    # @return [String] encoded error signature string.
    def self.encoded_error_signature(signature)
      Util.prefix_hex(Util.bin_to_hex(Util.keccak256(signature)[0..3]))
    end

    # Decodes a revert error payload.
    #
    # @param data [String] the hex-encoded revert data including selector.
    # @return [Array] decoded error arguments.
    def decode(data)
      types = inputs.map(&:type)
      payload = "0x" + data[10..]
      Eth::Abi.decode(types, payload)
    end
  end
end
