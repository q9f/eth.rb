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

  # Provides a Ruby implementation of the Ethereum Applicatoin Binary Interface (ABI).
  module Abi

    # Provides a module to decode transaction log events.
    module Event
      extend self

      # Compute topic for ABI event interface.
      #
      # @param interface [Hash] ABI event interface.
      # @return [String] a hex-string topic.
      def compute_topic(interface)
        sig = Abi.signature(interface)
        Util.prefix_hex(Util.bin_to_hex(Util.keccak256(sig)))
      end

      # Decodes a stream of receipt logs with a set of ABI interfaces.
      #
      # @param interfaces [Array] event ABI types.
      # @param logs [Array] transaction receipt logs
      # @return [Hash] an enumerator of decoded log objects.
      def decode_logs(interfaces, logs)
        Enumerator.new do |y|
          topic_to_interfaces = Hash[interfaces.map { |i| [compute_topic(i), i] }]

          logs.each do |log|
            result = { log: log }
            topics = log.fetch("topics", [])
            topic = topics[0]

            if interface = topic_to_interfaces[topic]
              result[:name] = interface.fetch("name")
              result[:signature] = Abi.signature(interface)
              result[:topic] = topic

              inputs = interface.fetch("inputs")
              data = log.fetch("data")
              anonymous = interface.fetch("anonymous", false)

              args, kwargs = decode_log(inputs, data, topics, anonymous)
              result[:args] = args
              result[:kwargs] = kwargs
            end

            y << result
          end
        end
      end

      # Decodes event log argument values.
      #
      # @param inputs [Array] event ABI types.
      # @param data [String] ABI event data to be decoded.
      # @param topics [Array] ABI event topics to be decoded.
      # @param anonymous [Boolean] If event signature is excluded from topics.
      # @return [[Array, Hash]] decoded positional arguments and decoded keyword arguments.
      # @raise [DecodingError] if decoding fails for type.
      def decode_log(inputs, data, topics, anonymous = false)
        topic_inputs, data_inputs = inputs.partition { |i| i["indexed"] }

        topic_types = topic_inputs.map { |i| i["type"] }
        data_types = data_inputs.map { |i| i["type"] }

        # If event is anonymous, all topics are arguments. Otherwise, the first
        # topic will be the event signature.
        if anonymous == false
          topics = topics[1..-1]
        end

        decoded_topics = topics.map.with_index { |t, i| Abi.decode([topic_types[i]], t)[0] }
        decoded_data = Abi.decode(data_types, data)

        args = []
        kwargs = {}

        inputs.each_with_index do |input, index|
          if input["indexed"]
            value = decoded_topics[topic_inputs.index(input)]
          else
            value = decoded_data[data_inputs.index(input)]
          end
          args[index] = value
          kwargs[input["name"].to_sym] = value
        end

        return args, kwargs
      end
    end
  end
end
