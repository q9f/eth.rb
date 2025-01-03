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

  # Provide classes for contract function input.
  class Contract::FunctionInput
    attr_accessor :type, :raw_type, :name

    # Constructor of the {Eth::Contract::FunctionInput} class.
    #
    # @param data [Hash] contract abi data.
    def initialize(data)
      @raw_type = data["type"]
      @type = Eth::Abi::Type.parse(data["type"], data["components"])
      @name = data["name"]
    end

    # Returns complete types with subtypes, e.g., `uint256`.
    def type
      @type.base_type + @type.sub_type + @type.dimensions.map { |dimension| "[#{dimension > 0 ? dimension : ""}]" }.join("")
    end

    # Returns parsed types.
    def parsed_type
      @type
    end
  end
end
