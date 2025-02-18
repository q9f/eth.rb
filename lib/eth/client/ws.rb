# Copyright (c) 2016-2025 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     ws://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Provides the {Eth} module.
require "websocket-client-simple"

module Eth
  class Client::Ws < Client
    # The host of the HTTP endpoint.
    attr_reader :host

    # The port of the HTTP endpoint.
    attr_reader :port

    # The full URI of the HTTP endpoint, including path.
    attr_reader :uri

    # Attribute indicator for SSL.
    attr_reader :ssl

    def initialize(host)
      super
      uri = URI.parse(host)
      raise ArgumentError, "Unable to parse the WS-URI!" unless ["ws", "wss"].include? uri.scheme
      @host = uri.host
      @port = uri.port
      @ssl = uri.scheme == "wss"
      if uri.query
        @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}?#{uri.query}")
      else
        @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}")
      end
    end

    def send_request(payload)
      ws = WebSocket::Client::Simple.connect @uri
      ws.on :message do |msg|
        puts "#{@uri}: #{msg}"
        # id = JSON.parse(JSON.generate(msg.to_s))["id"]
        # pp id
        # @response = msg.to_s
      end
      ws.on :error do |event|
        raise "Error connecting to #{@uri}: #{event}"
      end
      ws.on :close do
        puts "#{@uri}: connection closed"
      end
      ws.send(payload)
      # return JSON.generate({ "jsonrpc": "2.0", "id": 1, "result": "0x539" })
    end
  end
end
