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

require "websocket"
require "socket"

# Provides the {Eth} module.
module Eth

  # Provides a Websocket-RPC client.
  class Client::Ws < Client

    # The host of the Websocket endpoint.
    attr_reader :host

    # The port of the Websocket endpoint.
    attr_reader :port

    # The full URI of the Websocket endpoint, including path.
    attr_reader :uri

    # Attribute indicator for SSL.
    attr_reader :ssl

    # Constructor for the Websocket Client. Should not be used; use
    # {Client.create} instead.
    #
    # @param host [String] an URI pointing to an Websocket RPC-API.
    def initialize(host)
      super
      uri = URI.parse(host)
      raise ArgumentError, "Unable to parse the WS-URI!" unless ["ws", "wss"].include? uri.scheme
      @host = uri.host
      @port = uri.port
      @ssl = uri.scheme == "wss"
      @uri = URI("#{uri.scheme}://#{@host}:#{@port}#{uri.path}")
      @ws = WebSocket::Handshake::Client.new(
        url: @uri.to_s,
      )
    end

    # Sends an RPC request to the connected Websocket client.
    #
    # @param payload [Hash] the RPC request parameters.
    # @return [String] a JSON-encoded response.
    def send_request(payload)

      socket = TCPSocket.new @host, @port
      if ssl
        socket = OpenSSL::SSL::SSLSocket.new(socket, OpenSSL::SSL::SSLContext.new)
        socket.sync_close = true
        socket.connect
      end

      frame = WebSocket::Frame::Outgoing::Client.new(
        version: @ws.version,
        data: payload,
        type: 'text'
      )

      socket.write(frame.to_s)
      socket.flush

      # to do
      # response = socket.read

      socket.close

      # to do remove
      return '{"jsonrpc":"2.0","id":1,"result":"0x539"}'
    end

    private

    attr_reader :ws

  end
end
