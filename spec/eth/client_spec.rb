require "spec_helper"

# run `geth --dev --http` to provide both http and ipc to pass these tests

describe Client do
  let(:geth_dev_ipc_path) { "/tmp/geth.ipc" }
  let(:geth_dev_http_path) { "http://127.0.0.1:8545" }
  subject(:geth_dev_ipc) { Client.create geth_dev_ipc_path }
  subject(:geth_dev_http) { Client.create geth_dev_http_path }

  describe ".create .initialize" do
    it "creates an http client" do
      expect(geth_dev_ipc).to be
      expect(geth_dev_ipc).to be_instance_of Eth::Client::Ipc
      expect(geth_dev_ipc.path).to eq geth_dev_ipc_path
    end

    it "creates an ipc client" do
      expect(geth_dev_http).to be
      expect(geth_dev_http).to be_instance_of Eth::Client::Http
      expect(geth_dev_http.host).to eq "127.0.0.1"
      expect(geth_dev_http.port).to eq 8545
      expect(geth_dev_http.uri.to_s).to eq geth_dev_http_path
      expect(geth_dev_http.ssl).to be_falsy
    end

    it "functions as geth development client" do
      expect(geth_dev_ipc.id).to eq 0
      expect(geth_dev_ipc.chain_id).to eq Chain::PRIVATE_GETH
      expect(geth_dev_ipc.default_account.to_s).to eq Address.new("0x094e580f1c09995bda5c4944be29b611dff105b8").to_s
      expect(geth_dev_ipc.max_priority_fee_per_gas).to eq 0
      expect(geth_dev_ipc.max_fee_per_gas).to eq Tx::DEFAULT_GAS_PRICE
      expect(geth_dev_ipc.gas_limit).to eq Tx::DEFAULT_GAS_LIMIT
    end

    it "can query basic methods" do
      expect(geth_dev_http.get_balance "0x094e580f1c09995bda5c4944be29b611dff105b8").to eq 115792089237316195423570985008687907853269984665640564039457584007913129639927
      expect(geth_dev_http.get_nonce "0x094e580f1c09995bda5c4944be29b611dff105b8").to eq 0
      expect(geth_dev_http.reset_id).to eq 0
    end

    it "does not create dysfunctional clients" do
      expect { Client.create "ftp://127.0.0.1:8545" }.to raise_error ArgumentError, "Unable to detect client type!"
      expect { Client.create "/home/user/fun.txt" }.to raise_error ArgumentError, "Unable to detect client type!"
    end
  end
end
