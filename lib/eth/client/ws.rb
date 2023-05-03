# Copyright (c) 2016-2023 The Ruby-Eth Contributors
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

require "websocket-client-simple"

# Provides the {Eth} module.
module Eth

  # Provides an WebSocket client.
  class Client::Ws < Client

    # The host of the HTTP endpoint.
    attr_reader :host

    # Constructor for the WebSocket Client. Should not be used; use
    # {Client.create} intead.
    #
    # @param host [String] an URI pointing to an HTTP RPC-API.
    def initialize(host)
      super
      @host = host
      setup_websocket
    end

    # Sends an RPC request to the connected WebSocket client.
    #
    # @param payload [Hash] the RPC request parameters.
    # @return [String] a JSON-encoded response.
    def send(payload)
      @ws.send(payload.to_json)
    end

    private

    def setup_websocket
      @ws = WebSocket::Client::Simple.connect @host

      @ws.on :message do |msg|
        puts ">> #{msg.data}"
      end
      @ws.on :open do
        puts "-- websocket open (#{@host})"
      end
      @ws.on :close do |e|
        puts "-- websocket close (#{e.inspect})"
        exit 1
      end
      @ws.on :error do |e|
        puts "-- error (#{e.inspect})"
      end
    end
  end
end
