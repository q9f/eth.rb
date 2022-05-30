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

  # Provide classes for contract initializer.
  class Contract::Initializer
    attr_accessor :contracts, :file

    # Constructor of the {Eth::Contract::Initializer} class.
    #
    # @param file [String] file path to solidity code.
    def initialize(file)
      sol_output = Eth::Solidity.new.compile(file)
      contracts = sol_output.keys

      @contracts = []
      contracts.each do |contract|
        abi = sol_output[contract]["abi"]
        name = contract
        code = sol_output[contract]["bin"]
        @contracts << Contract.new(name, code, abi)
      end
    end

    # Builds and returns all contracts.
    def build_all
      @contracts.each do |contract|
        contract.build
      end
    end
  end
end
