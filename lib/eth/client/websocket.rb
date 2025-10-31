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

require "socket"
require "openssl"
require "uri"
require "base64"
require "securerandom"
require "digest/sha1"
require "thread"

# Provides the {Eth} module.
module Eth

  # Provides a WS/S-RPC client with automatic reconnection support.
  class Client::Ws < Client

    # The host of the WebSocket endpoint.
    attr_reader :host

    # The port of the WebSocket endpoint.
    attr_reader :port

    # The full URI of the WebSocket endpoint, including path.
    attr_reader :uri

    # Attribute indicator for SSL.
    attr_reader :ssl

    # Constructor for the WebSocket Client. Should not be used; use
    # {Client.create} instead.
    #
    # @param host [String] a URI pointing to a WebSocket RPC-API.
    def initialize(host)
      super
      @uri = URI.parse(host)
      raise ArgumentError, "Unable to parse the WebSocket-URI!" unless %w[ws wss].include?(@uri.scheme)
      @host = @uri.host
      @port = @uri.port
      @ssl = @uri.scheme == "wss"
      @path = build_path(@uri)
      @mutex = Mutex.new
      @socket = nil
      @fragments = nil
    end

    # Sends an RPC request to the connected WebSocket endpoint.
    #
    # @param payload [Hash] the RPC request parameters.
    # @return [String] a JSON-encoded response.
    def send_request(payload)
      attempts = 0
      begin
        attempts += 1
        @mutex.synchronize do
          ensure_socket
          write_frame(@socket, payload)
          return read_message(@socket)
        end
      rescue IOError, SystemCallError => e
        @mutex.synchronize { close_socket }
        retry if attempts < 2
        raise e
      end
    end

    # Closes the underlying WebSocket connection.
    #
    # @return [void]
    def close
      @mutex.synchronize { close_socket }
    end

    private

    def ensure_socket
      return if @socket && !@socket.closed?

      socket = open_socket
      begin
        perform_handshake(socket)
        @socket = socket
        @fragments = nil
      rescue StandardError
        begin
          socket.close unless socket.closed?
        rescue IOError, SystemCallError
          nil
        end
        @socket = nil
        raise
      end
    end

    # Establishes the TCP socket for the RPC connection and upgrades it to TLS
    # when a secure endpoint is requested. TLS sessions enforce peer
    # verification, load the default system trust store, and enable hostname
    # verification when the current OpenSSL bindings support it.
    #
    # @return [TCPSocket, OpenSSL::SSL::SSLSocket] the established socket.
    # @raise [IOError, SystemCallError, OpenSSL::SSL::SSLError] if the socket
    #   cannot be opened or the TLS handshake fails.
    def open_socket
      tcp = TCPSocket.new(@host, @port)
      return tcp unless @ssl

      context = OpenSSL::SSL::SSLContext.new
      params = { verify_mode: OpenSSL::SSL::VERIFY_PEER }
      params[:verify_hostname] = true if context.respond_to?(:verify_hostname=)
      context.set_params(params)
      context.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)

      ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp, context)
      ssl_socket.hostname = @host
      ssl_socket.sync_close = true
      ssl_socket.connect
      ssl_socket
    end

    def perform_handshake(socket)
      key = Base64.strict_encode64(SecureRandom.random_bytes(16))
      request = build_handshake_request(key)
      socket.write(request)
      response = read_handshake_response(socket)
      verify_handshake!(response, key)
    end

    def build_handshake_request(key)
      origin = @ssl ? "https://#{@host}" : "http://#{@host}"
      "GET #{@path} HTTP/1.1\r\n" \
      "Host: #{@host}:#{@port}\r\n" \
      "Upgrade: websocket\r\n" \
      "Connection: Upgrade\r\n" \
      "Sec-WebSocket-Version: 13\r\n" \
      "Sec-WebSocket-Key: #{key}\r\n" \
      "Origin: #{origin}\r\n\r\n"
    end

    def read_handshake_response(socket)
      response = +""
      until response.end_with?("\r\n\r\n")
        chunk = socket.readpartial(1024)
        raise IOError, "Incomplete WebSocket handshake" if chunk.nil?
        response << chunk
      end
      response
    rescue EOFError
      raise IOError, "Incomplete WebSocket handshake"
    end

    def verify_handshake!(response, key)
      accept = response[/Sec-WebSocket-Accept:\s*(.+)\r/i, 1]&.strip
      expected = Base64.strict_encode64(Digest::SHA1.digest("#{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
      unless response.start_with?("HTTP/1.1 101") && accept == expected
        raise IOError, "WebSocket handshake failed"
      end
    end

    def write_frame(socket, payload, opcode = 0x1)
      frame_payload = payload.is_a?(String) ? payload.dup : payload.to_s
      mask_key = SecureRandom.random_bytes(4)
      header = [0x80 | opcode]

      length = frame_payload.bytesize
      if length <= 125
        header << (0x80 | length)
      elsif length <= 0xFFFF
        header << (0x80 | 126)
        header.concat([length].pack("n").bytes)
      else
        header << (0x80 | 127)
        header.concat([length].pack("Q>").bytes)
      end

      masked_payload = apply_mask(frame_payload, mask_key)
      socket.write(header.pack("C*") + mask_key + masked_payload)
    end

    def read_message(socket)
      loop do
        frame = read_frame(socket)
        return frame if frame
      end
    end

    def read_frame(socket)
      header = read_bytes(socket, 2)
      byte1, byte2 = header.bytes
      opcode = byte1 & 0x0F
      masked = (byte2 & 0x80) == 0x80
      length = byte2 & 0x7F

      length = read_bytes(socket, 2).unpack1("n") if length == 126
      length = read_bytes(socket, 8).unpack1("Q>") if length == 127

      mask_key = masked ? read_bytes(socket, 4).bytes : nil
      payload = read_bytes(socket, length)
      payload_bytes = payload.bytes
      if mask_key
        payload_bytes.map!.with_index { |byte, index| byte ^ mask_key[index % 4] }
      end
      data = payload_bytes.pack("C*")

      case opcode
      when 0x0
        (@fragments ||= +"") << data
        if (byte1 & 0x80) == 0x80
          message = @fragments.dup
          @fragments = nil
          message
        else
          nil
        end
      when 0x1, 0x2
        if (byte1 & 0x80) == 0x80
          data
        else
          @fragments = data
          nil
        end
      when 0x8
        close_socket
        raise IOError, "WebSocket closed"
      when 0x9
        write_frame(socket, data, 0xA)
        nil
      when 0xA
        nil
      else
        nil
      end
    end

    def read_bytes(socket, length)
      data = +""
      while data.bytesize < length
        chunk = socket.read(length - data.bytesize)
        raise IOError, "Unexpected end of WebSocket stream" if chunk.nil? || chunk.empty?
        data << chunk
      end
      data
    end

    def apply_mask(payload, mask_key)
      mask_bytes = mask_key.bytes
      payload.bytes.map.with_index { |byte, index| byte ^ mask_bytes[index % 4] }.pack("C*")
    end

    def close_socket
      return unless @socket

      begin
        write_frame(@socket, [1000].pack("n"), 0x8)
      rescue IOError, SystemCallError
        # ignore errors while closing
      ensure
        begin
          @socket.close unless @socket.closed?
        rescue IOError, SystemCallError
          nil
        end
        @socket = nil
        @fragments = nil
      end
    end

    def build_path(uri)
      path = uri.path
      path = "/" if path.nil? || path.empty?
      query = uri.query
      path += "?#{query}" if query
      path
    end
  end
end
