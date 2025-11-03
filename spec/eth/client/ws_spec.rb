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
require "digest/sha2"

describe Client::Ws do

  # Minimal WebSocket server implementing JSON-RPC responses for testing.
  class DummyWebsocketServer
    DEFAULT_ACCOUNT = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1"

    attr_reader :port, :default_account

    def initialize
      @server = TCPServer.new("127.0.0.1", 0)
      @port = @server.addr[1]
      @thread = nil
      @running = false
      @default_account = DEFAULT_ACCOUNT
      @accounts = [DEFAULT_ACCOUNT]
      @balances = Hash.new(0)
      @balances[normalize_address(DEFAULT_ACCOUNT)] = 2 * 10 ** 18
      @nonces = Hash.new(0)
      @transactions = {}
      @receipts = {}
      @block_number = 10
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
      origin = request[/Origin:\s*(.+)\r/i, 1]&.strip
      expected_origins = [
        "http://127.0.0.1:#{@port}",
        "http://localhost:#{@port}",
      ]
      unless expected_origins.include?(origin)
        socket.write("HTTP/1.1 403 Forbidden\r\n")
        socket.write("Connection: close\r\n\r\n")
        raise IOError, "Forbidden origin"
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
      params = message["params"] || []
      case method
      when "eth_chainId"
        success(id, "0x1")
      when "eth_blockNumber"
        success(id, to_hex(@block_number))
      when "eth_accounts"
        success(id, @accounts)
      when "eth_getBalance"
        address = normalize_address(params[0])
        success(id, to_hex(@balances[address]))
      when "eth_getTransactionCount"
        address = normalize_address(params[0])
        success(id, to_hex(@nonces[address]))
      when "eth_sendTransaction"
        tx_hash = record_transaction(params[0] || {})
        success(id, tx_hash)
      when "eth_getTransactionByHash"
        success(id, @transactions[params[0]])
      when "eth_getTransactionReceipt"
        success(id, @receipts[params[0]])
      when "eth_call"
        success(id, "0x")
      else
        error(id, "Method not found")
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

    def success(id, result)
      {
        "jsonrpc" => "2.0",
        "id" => id,
        "result" => result,
      }
    end

    def error(id, message)
      {
        "jsonrpc" => "2.0",
        "id" => id,
        "error" => { "code" => -32601, "message" => message },
      }
    end

    def record_transaction(tx)
      from = normalize_address(tx["from"] || DEFAULT_ACCOUNT)
      to = normalize_address(tx["to"])
      value = hex_to_int(tx["value"])
      nonce = @nonces[from]
      @nonces[from] += 1
      @balances[from] -= value
      @balances[to] += value if to
      hash = build_tx_hash(from, to, nonce, value)
      @transactions[hash] = {
        "hash" => hash,
        "from" => from,
        "to" => to,
        "value" => to_hex(value),
        "blockNumber" => to_hex(@block_number),
      }
      @receipts[hash] = {
        "transactionHash" => hash,
        "status" => "0x1",
        "blockNumber" => to_hex(@block_number),
      }
      hash
    end

    def build_tx_hash(from, to, nonce, value)
      seed = [from, to, nonce, value].compact.join(":")
      "0x#{Digest::SHA256.hexdigest(seed)}"
    end

    def normalize_address(address)
      return nil if address.nil?
      address.downcase
    end

    def hex_to_int(value)
      return 0 if value.nil?
      value = value.delete_prefix("0x")
      return 0 if value.empty?
      value.to_i(16)
    end

    def to_hex(number)
      "0x#{number.to_i.to_s(16)}"
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

  describe "handshake" do
    it "uses localhost as origin for loopback endpoints" do
      request = client.send(:build_handshake_request, "test-key")
      expect(request).to include("Origin: http://localhost:#{server.port}\r\n")
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

  describe "account interactions" do
    let(:default_address) { Address.new(server.default_account) }
    let(:recipient) { Address.new("0x1ef5f5e0b3bbf3b6a4a8d8cd75b8d907af9e4661") }

    it "exposes the default account" do
      expect(client.default_account.to_s).to eq(default_address.to_s)
    end

    it "reports balances and nonces for known accounts" do
      expect(client.get_balance(default_address)).to eq(2 * Unit::ETHER)
      expect(client.get_nonce(default_address)).to eq(0)
    end

    it "processes transfers and updates RPC derived state" do
      initial_sender_balance = client.get_balance(default_address)
      amount = Unit::ETHER

      tx_hash = client.transfer(recipient, amount)

      expect(tx_hash).to start_with("0x")
      expect(client.get_nonce(default_address)).to eq(1)
      expect(client.tx_mined?(tx_hash)).to be true
      expect(client.tx_succeeded?(tx_hash)).to be true
      expect(client.get_balance(recipient)).to eq(amount)
      expect(client.get_balance(default_address)).to eq(initial_sender_balance - amount)
    end

    it "resets the RPC id counter" do
      client.eth_block_number
      client.eth_chain_id
      expect(client.reset_id).to eq(0)
      expect(client.instance_variable_get(:@id)).to eq(0)
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
