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

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
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

      # A decoded event log.
      class LogDescription
        # The event ABI interface used to decode the log.
        attr_accessor :event_interface

        # The the input argument of the event.
        attr_accessor :args

        # The named input argument of the event.
        attr_accessor :kwargs

        # The topic hash.
        attr_accessor :topic

        # Decodes event log argument values.
        #
        # @param event_interface [Hash] event ABI type.
        # @param log [Hash] transaction receipt log
        def initialize(event_interface, log)
          @event_interface = event_interface

          inputs = event_interface.fetch("inputs")
          data = log.fetch("data")
          topics = log.fetch("topics", [])
          anonymous = event_interface.fetch("anonymous", false)

          @topic = topics[0] if !anonymous
          @args, @kwargs = Event.decode_log(inputs, data, topics, anonymous)
        end

        # The event name. (e.g. Transfer)
        def name
          @name ||= event_interface.fetch("name")
        end

        # The event signature. (e.g. Transfer(address,address,uint256))
        def signature
          @signature ||= Abi.signature(event_interface)
        end
      end

      # Decodes a stream of receipt logs with a set of ABI interfaces.
      #
      # @param interfaces [Array] event ABI types.
      # @param logs [Array] transaction receipt logs
      # @return [Hash] an enumerator of LogDescription objects.
      def decode_logs(interfaces, logs)
        Enumerator.new do |y|
          topic_to_interfaces = Hash[interfaces.map { |i| [compute_topic(i), i] }]

          logs.each do |log|
            topic = log.fetch("topics", [])[0]
            if topic && interface = topic_to_interfaces[topic]
              y << [log, LogDescription.new(interface, log)]
            else
              y << [log, nil]
            end
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
