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

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
  module Abi

    # Provides a module to decode transaction input data.
    module Function
      extend self

      # Build function signature string from ABI interface.
      #
      # @param interface [Hash] ABI function interface.
      # @return [String] interface signature string.
      def signature(interface)
        name = interface.fetch("name")
        inputs = interface.fetch("inputs", [])
        types = inputs.map { |i| type(i) }
        "#{name}(#{types.join(",")})"
      end

      # Compute selector for ABI function interface.
      #
      # @param interface [Hash] ABI function interface.
      # @return [String] a hex-string selector.
      def selector(interface)
        sig = signature(interface)
        Util.prefix_hex(Util.bin_to_hex(Util.keccak256(sig))[0, 8])
      end

      # Gets the input type for functions.
      #
      # @param input [Hash] function input.
      # @return [String] input type.
      def type(input)
        if input["type"] == "tuple"
          "(#{input["components"].map { |c| type(c) }.join(",")})"
        elsif input["type"] == "enum"
          "uint8"
        else
          input["type"]
        end
      end

      # A decoded function call.
      class CallDescription
        # The function ABI interface used to decode the call.
        attr_accessor :function_interface

        # The positional arguments of the call.
        attr_accessor :args

        # The named arguments of the call.
        attr_accessor :kwargs

        # The function selector.
        attr_accessor :selector

        # Creates a description object for a decoded function call.
        #
        # @param function_interface [Hash] function ABI type.
        # @param selector [String] function selector hex-string.
        # @param args [Array] decoded positional arguments.
        # @param kwargs [Hash] decoded keyword arguments.
        def initialize(function_interface, selector, args, kwargs)
          @function_interface = function_interface
          @selector = selector
          @args = args
          @kwargs = kwargs
        end

        # The function name. (e.g. transfer)
        def name
          @name ||= function_interface.fetch("name")
        end

        # The function signature. (e.g. transfer(address,uint256))
        def signature
          @signature ||= Function.signature(function_interface)
        end
      end

      # Decodes a transaction input with a set of ABI interfaces.
      #
      # @param interfaces [Array] function ABI types.
      # @param data [String] transaction input data.
      # @return [CallDescription, nil] a CallDescription object or nil if selector unknown.
      def decode(interfaces, data)
        data = Util.remove_hex_prefix(data)
        selector = Util.prefix_hex(data[0, 8])
        payload = Util.prefix_hex(data[8..] || "")

        selector_to_interfaces = Hash[interfaces.map { |i| [selector(i), i] }]
        if (interface = selector_to_interfaces[selector])
          inputs = interface.fetch("inputs", [])
          types = inputs.map { |i| type(i) }
          args = Abi.decode(types, payload)
          kwargs = {}
          inputs.each_with_index do |input, i|
            name = input.fetch("name", "")
            kwargs[name.to_sym] = args[i] unless name.empty?
          end
          CallDescription.new(interface, selector, args, kwargs)
        end
      end
    end
  end
end
