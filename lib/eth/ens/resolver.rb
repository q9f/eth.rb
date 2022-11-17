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
  # Provides ENS specific functionality
  # ref: https://ens.domains
  module Ens

    # Utility class for resolving ENS names to Ethereum addresses
    class Resolver

      # The default address for ENS, which applies to most chains
      DEFAULT_ADDRESS = "0x00000000000c2e074ec69a0dfb2997ba6c7d2e1e".freeze

      # Create an instance of the ENS Resolver
      #
      # @param ens_name [String] The ENS name, eg: fancy.eth
      # @param ens_name [String] The ENS name, eg: fancy.eth
      def initialize(client, address = DEFAULT_ADDRESS)
        @client = client
        @contract = Eth::Contract.from_abi(
          name: "ENS",
          address: address,
          abi: JSON.parse(File.read(File.join(File.dirname(__FILE__), "../../../abis/ens.json"))),
        )
      end

      # Resolve an ENS name to an address
      #
      # @param ens_name [String] The ENS name, eg: fancy.eth
      # @return [String] The owner address of the name, as a hex string
      def resolve(ens_name)
        @client.call(@contract, "owner", namehash(ens_name))
      end

      # Generate node for the given domain name
      # See: https://docs.ens.domains/contract-api-reference/name-processing
      #
      # @param ens_name [String] The ENS name, eg: fancy.eth
      # @return [String] The node as a hex string
      def namehash(ens_name)
        node = ("0" * 64)
        name = normalize(ens_name)
        name.split(".").reverse.each do |label|
          hash = Digest::Keccak.new(256).hexdigest(label)
          node = Digest::Keccak.new(256).hexdigest([node + hash].pack("H*"))
        end
        "0x#{node}"
      end

      # Normalize a string as specified by http://unicode.org/reports/tr46/
      #
      # @param input [String] The input string
      # @return [String] The normalized output string
      def normalize(input)
        # TODO: This is fairly complicated, and there doesn't seem to be a ruby
        # library which can handle it perfectly.
        # https://www.unicode.org/reports/tr46/tr46-27.html
        input.downcase
      end
    end
  end
end
