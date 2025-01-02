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

  # Provides ENS specific functionality
  # ref: https://ens.domains
  module Ens

    # Utility class for resolving ENS names to Ethereum addresses
    class Resolver

      # The client instance used to resolve the ENS.
      attr_accessor :client

      # The address of the ENS registry on the given chain.
      attr_accessor :registry

      # Create an instance of the ENS Resolver.
      #
      # @param client [Eth::Client] The client instance used to resolve the ENS.
      # @param address [String] The address of the ENS registry on the given chain.
      def initialize(client, address = DEFAULT_ADDRESS)
        @client = client
        @registry = Eth::Contract.from_abi(
          name: "ENSRegistryWithFallback",
          address: address,
          abi: JSON.parse(File.read(File.join(File.dirname(__FILE__), "../../../abi/ens_registry.json"))),
        )
      end

      # Resolve an ENS name owner.
      #
      # @param ens_name [String] The ENS name, e.g., `fancy.eth`.
      # @return [String] The owner address of the name as a hex string.
      def owner(ens_name)
        @client.call(@registry, "owner", namehash(ens_name))
      end

      # Retrieve the public resolver for the given ENS name.
      #
      # @param ens_name [String] The ENS name, e.g., `fancy.eth`.
      # @return [Eth::Contract] The public resolver contract that can be used
      #   to resolve ENS names.
      def resolver(ens_name)
        address = @client.call(@registry, "resolver", namehash(ens_name))
        Eth::Contract.from_abi(
          name: "ENSPublicResolver",
          address: address,
          abi: JSON.parse(File.read(File.join(File.dirname(__FILE__), "../../../abi/ens_resolver.json"))),
        )
      end

      # Resolve an ENS name to an address.
      #
      # @param ens_name [String] The ENS name, e.g., `fancy.eth`.
      # @return [String] The owner address of the name as a hex string.
      def resolve(ens_name, coin_type = Ens::CoinType::ETHEREUM)
        if coin_type === Ens::CoinType::ETHEREUM
          return @client.call(resolver(ens_name), "addr", namehash(ens_name))
        elsif coin_type === Ens::CoinType::ETHEREUM_CLASSIC
          data = @client.call(resolver(ens_name), "addr", namehash(ens_name), coin_type)
          return Util.bin_to_prefixed_hex data
        else
          raise NotImplementedError, "Coin type #{coin_type} not implemented!"
        end
      end

      # Resolve a text record for a given ENS name.
      #
      # @param ens_name [String] The ENS name, e.g., `fancy.eth`.
      # @param key [String] The key for the text record, e.g., `url`.
      # @return [String] The text record.
      def text(ens_name, key = "description")
        @client.call(resolver(ens_name), "text", namehash(ens_name), key)
      end

      # Generate node for the given domain name
      # See: https://docs.ens.domains/contract-api-reference/name-processing
      #
      # @param ens_name [String] The ENS name, e.g., `fancy.eth`.
      # @return [String] The node as a hex string.
      def namehash(ens_name)
        node = Util.hex_to_bin("0" * 64)
        name = normalize(ens_name)
        name.split(".").reverse.each do |label|
          hash = Util.keccak256(label)
          node = Util.keccak256(node + hash)
        end
        Util.bin_to_prefixed_hex node
      end

      # Normalize a string as specified by http://unicode.org/reports/tr46/
      #
      # @param input [String] The input string
      # @return [String] The normalized output string
      def normalize(input)
        name = input.dup
        if name.gsub!(/[`~!@#$%^&*()_=+\[\]{}<>,;:'"\/\\|?]/, "").nil?
          return input.downcase
        else
          raise ArgumentError, "Provided ENS name contains illegal characters: #{input}"
        end
      end
    end
  end
end
