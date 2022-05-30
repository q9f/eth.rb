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

# -*- encoding : ascii-8bit -*-

# Provides the {Eth} module.
module Eth

  # Provides the methods for smart contract function.
  class Contract::Function
    attr_accessor :name, :inputs, :outputs, :signature, :constant, :function_string

    # Constructor of the {Eth::Function} class.
    #
    # @param data [Hash] function input and output data.
    def initialize(data)
      @name = data["name"]
      @constant = data["constant"]
      @inputs = data["inputs"].map do |input|
        Eth::Contract::FunctionInput.new(input)
      end
      @outputs = data["outputs"].collect do |output|
        Eth::Contract::FunctionOutput.new(output)
      end
      @function_string = self.class.calc_signature(@name, @inputs)
      @signature = self.class.encoded_function_signature(@function_string)
    end

    # Creates function strings.
    #
    # @param name [String] function name.
    # @param inputs [Array<Eth::Contract::FunctionInput>] function input class list.
    # @return [String] function string.
    def self.calc_signature(name, inputs)
      "#{name}(#{inputs.collect { |x| x.type }.join(",")})"
    end

    # Encodes a function signature.
    #
    # @param signature [String] function signature.
    # @return [String] encoded function signature string.
    def self.encoded_function_signature(signature)
      Util.bin_to_hex Util.keccak256(signature)[0..3]
    end
  end
end
