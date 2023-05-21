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
require "logger"

# Provides the {Eth} module.
module Eth

  # Provides an WebSocket client.
  class Client::Ws < Client

    # The host of the WebSocket endpoint.
    attr_reader :host

    # The port of the HTTP endpoint.
    attr_reader :port

    # The full URI of the HTTP endpoint, including path.
    attr_reader :uri

    # Attribute indicator for SSL.
    attr_reader :ssl

    # Constructor for the WebSocket Client. Should not be used; use
    # {Client.create} intead.
    #
    # @param host [String] an URI pointing to an HTTP RPC-API.
    def initialize(host)
      super
      uri = URI.parse(host)
      raise ArgumentError, "Unable to parse the WebSocket-URI!" unless ["ws", "wss"].include? uri.scheme
      @host = uri.host
      @port = uri.port
      @ssl = uri.scheme == "wss"
      @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}")
      setup_websocket
    end

    # Sends an RPC request to the connected WebSocket client.
    #
    # @param payload [Hash] the RPC request parameters.
    # @return [Integer] Number of bytes sent by this method.
    def send_request(payload)
      @ws.send(payload.to_json)
    end

    def open?
      @ws.open?
    end

    private

    def setup_websocket
      logger = Logger.new(STDOUT)
      logger.level = Logger::Severity::WARN

      @ws = WebSocket::Client::Simple.connect @uri.to_s

      @ws.on :message do |msg|
        msg.data
      end

      @ws.on :open do
        logger.info "websocket open (#{@host})"
      end

      @ws.on :close do |e|
        logger.info "websocket close (#{e.inspect})"
      end

      @ws.on :error do |e|
        logger.error "websocket error (#{e.inspect})"
      end
    end
  end
end
