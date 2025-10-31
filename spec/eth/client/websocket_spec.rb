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

require "spec_helper"
require "json"
require "socket"
require "base64"
require "digest/sha1"

describe Client::Websocket do

  # Minimal WebSocket server implementing JSON-RPC responses for testing.
  class DummyWebsocketServer
    attr_reader :port

    def initialize
      @server = TCPServer.new("127.0.0.1", 0)
      @port = @server.addr[1]
      @thread = nil
      @running = false
    end

    def start
      @running = true
      @thread = Thread.new { serve }
    end

    def stop
      @running = false
      begin
        @server.close
      rescue IOError
        nil
      end
      @thread&.join
    end

    private

    def serve
      while @running
        begin
          socket = @server.accept
        rescue IOError, Errno::EBADF
          break
        end
        handle_client(socket)
      end
    end

    def handle_client(socket)
      perform_handshake(socket)
      loop do
        frame = read_frame(socket)
        break if frame.nil?

        case frame[:opcode]
        when 0x1
          message = JSON.parse(frame[:data])
          response = rpc_response_for(message)
          send_frame(socket, response.to_json)
        when 0x8
          send_close(socket)
          break
        when 0x9
          send_frame(socket, frame[:data], 0xA)
        end
      end
    rescue IOError, JSON::ParserError
      nil
    ensure
      begin
        socket.close unless socket.closed?
      rescue IOError
        nil
      end
    end

    def perform_handshake(socket)
      request = +""
      while (line = socket.gets)
        break if line == "\r\n"
        request << line
      end
      key = request[/Sec-WebSocket-Key:\s*(.+)\r/i, 1]&.strip
      accept = Base64.strict_encode64(Digest::SHA1.digest("#{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
      socket.write("HTTP/1.1 101 Switching Protocols\r\n")
      socket.write("Upgrade: websocket\r\n")
      socket.write("Connection: Upgrade\r\n")
      socket.write("Sec-WebSocket-Accept: #{accept}\r\n\r\n")
    end

    def rpc_response_for(message)
      method = message["method"]
      id = message["id"]
      case method
      when "eth_chainId"
        { "jsonrpc" => "2.0", "id" => id, "result" => "0x1" }
      when "eth_blockNumber"
        { "jsonrpc" => "2.0", "id" => id, "result" => "0xa" }
      else
        {
          "jsonrpc" => "2.0",
          "id" => id,
          "error" => { "code" => -32601, "message" => "Method not found" },
        }
      end
    end

    def read_frame(socket)
      header = socket.read(2)
      return nil if header.nil?

      byte1, byte2 = header.bytes
      opcode = byte1 & 0x0F
      length = byte2 & 0x7F
      masked = (byte2 & 0x80) != 0

      if length == 126
        length = socket.read(2).unpack1("n")
      elsif length == 127
        length = socket.read(8).unpack1("Q>")
      end

      mask_key = masked ? socket.read(4).bytes : []
      payload = socket.read(length) || ""
      payload_bytes = payload.bytes
      if masked
        payload_bytes.map!.with_index { |byte, index| byte ^ mask_key[index % 4] }
      end
      { opcode: opcode, data: payload_bytes.pack("C*") }
    end

    def send_frame(socket, payload, opcode = 0x1)
      payload = payload.to_s
      header = [0x80 | opcode]
      length = payload.bytesize
      if length <= 125
        header << length
      elsif length <= 0xFFFF
        header << 126
        header.concat([length].pack("n").bytes)
      else
        header << 127
        header.concat([length].pack("Q>").bytes)
      end
      socket.write(header.pack("C*") + payload)
    end

    def send_close(socket)
      send_frame(socket, [1000].pack("n"), 0x8)
    end
  end

  let(:server) { DummyWebsocketServer.new }
  let(:endpoint) { "ws://127.0.0.1:#{server.port}" }
  subject(:client) { described_class.new(endpoint) }

  before do
    server.start
  end

  after do
    client.close
    server.stop
  end

  describe ".create" do
    it "detects a websocket endpoint" do
      expect(Client.create(endpoint)).to be_a(described_class)
    end
  end

  describe "#send_request" do
    it "performs JSON-RPC calls over websocket" do
      expect(client.eth_chain_id["result"]).to eq("0x1")
      expect(client.chain_id).to eq 1
      expect(client.eth_block_number["result"]).to eq("0xa")
    end

    it "raises rpc errors returned by the server" do
      expect { client.send(:send_command, "eth_unknown", []) }.to raise_error(Client::RpcError, "Method not found")
    end
  end

  describe "#close" do
    it "closes the websocket connection idempotently" do
      expect { client.close }.not_to raise_error
      expect { client.close }.not_to raise_error
    end
  end

  describe "#open_socket" do
    it "verifies tls certificates for wss endpoints" do
      tcp_socket = instance_double(TCPSocket)
      expect(TCPSocket).to receive(:new).with("example.org", 443).and_return(tcp_socket)

      ssl_socket = instance_double(OpenSSL::SSL::SSLSocket)
      allow(ssl_socket).to receive(:hostname=).with("example.org")
      allow(ssl_socket).to receive(:sync_close=).with(true)
      allow(ssl_socket).to receive(:connect)

      captured_context = nil
      allow(OpenSSL::SSL::SSLContext).to receive(:new).and_wrap_original do |original, *args|
        captured_context = original.call(*args)
        captured_context
      end

      allow(OpenSSL::SSL::SSLSocket).to receive(:new) do |socket, context|
        expect(socket).to eq(tcp_socket)
        expect(context.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
        expect(context.cert_store).to be_a(OpenSSL::X509::Store)
        ssl_socket
      end

      wss_client = described_class.new("wss://example.org/socket")
      expect(wss_client.send(:open_socket)).to eq(ssl_socket)

      if captured_context.respond_to?(:verify_hostname)
        expect(captured_context.verify_hostname).to be true
      end
    end
  end
end
