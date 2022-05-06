require "spec_helper"

# run `geth --dev --http --ipcpath /tmp/geth.ipc`
# to provide both http and ipc to pass these tests.

describe Client do
  let(:geth_dev_ipc_path) { "/tmp/geth.ipc" }
  let(:geth_dev_http_path) { "http://127.0.0.1:8545" }
  subject(:geth_dev_ipc) { Client.create geth_dev_ipc_path }
  subject(:geth_dev_http) { Client.create geth_dev_http_path }

  describe ".create .initialize" do
    it "creates an http client" do
      expect(geth_dev_ipc).to be
      expect(geth_dev_ipc).to be_instance_of Client::Ipc
      expect(geth_dev_ipc.path).to eq geth_dev_ipc_path
    end

    it "creates an ipc client" do
      expect(geth_dev_http).to be
      expect(geth_dev_http).to be_instance_of Client::Http
      expect(geth_dev_http.host).to eq "127.0.0.1"
      expect(geth_dev_http.port).to eq 8545
      expect(geth_dev_http.uri.to_s).to eq geth_dev_http_path
      expect(geth_dev_http.ssl).to be_falsy
    end

    it "functions as geth development client" do
      expect(geth_dev_ipc.id).to eq 0
      expect(geth_dev_ipc.chain_id).to eq Chain::PRIVATE_GETH
      expect(geth_dev_ipc.default_account).to be_instance_of Address
      expect(geth_dev_ipc.max_priority_fee_per_gas).to eq 0
      expect(geth_dev_ipc.max_fee_per_gas).to eq Tx::DEFAULT_GAS_PRICE
      expect(geth_dev_ipc.gas_limit).to eq Tx::DEFAULT_GAS_LIMIT
    end

    it "can query basic methods" do

      # the default account is prefunded; this test fails if you manually drain the account to zero
      expect(geth_dev_http.get_balance geth_dev_http.default_account).to be > 0
      expect(geth_dev_http.get_nonce geth_dev_http.default_account).to be >= 0
      expect(geth_dev_http.reset_id).to eq 0
    end

    it "does not create dysfunctional clients" do
      expect { Client.create "ftp://127.0.0.1:8545" }.to raise_error ArgumentError, "Unable to detect client type!"
      expect { Client.create "/home/user/fun.txt" }.to raise_error ArgumentError, "Unable to detect client type!"
    end
  end

  describe ".transfer .transfer_and_wait" do
    subject(:test_key) { Key.new }
    subject(:another_key) { Key.new }

    it "funds a random account and returns the money" do
      geth_dev_http.transfer_and_wait(test_key.address, 1337 * Unit::ETHER)
      expect(geth_dev_http.get_balance test_key.address).to eq 1337 * Unit::ETHER
      geth_dev_ipc.transfer_and_wait(geth_dev_ipc.default_account, 42 * Unit::ETHER, test_key)
      expect(geth_dev_ipc.get_nonce test_key.address).to eq 1
    end

    it "funds a random account using legacy transactions" do
      geth_dev_http.transfer_and_wait(another_key.address, 69 * Unit::ETHER, nil, true)
      expect(geth_dev_http.get_balance another_key.address).to eq 69 * Unit::ETHER
      geth_dev_ipc.transfer_and_wait(geth_dev_ipc.default_account, 23 * Unit::ETHER, another_key, true)
      expect(geth_dev_ipc.get_nonce another_key.address).to eq 1
    end
  end

  describe ".deploy .deploy_and_wait" do
    subject(:contract) { Eth::Contract.create(file: "spec/fixtures/contracts/dummy.sol") }
    subject(:test_key) { Key.new }

    it "deploy the contract and the address is returned" do
      address = geth_dev_http.deploy_and_wait(contract)
      expect(address).to start_with "0x"
      expect(address.length).to eq 42
      address = geth_dev_ipc.deploy_and_wait(contract)
      expect(address).to start_with "0x"
      expect(address.length).to eq 42
    end

    it "deploy the contract with key" do
      geth_dev_http.transfer_and_wait(test_key.address, 1337 * Unit::ETHER)
      address = geth_dev_http.deploy_and_wait(contract, sender_key: test_key)
      expect(address).to start_with "0x"
    end

    it "deploy the contract using legacy transactions" do
      address = geth_dev_http.deploy_and_wait(contract, legacy: true)
      expect(address).to start_with "0x"
    end
  end

  describe ".call" do
    subject(:test_key) { Key.new }
    subject(:contract) { Eth::Contract.create(file: "spec/fixtures/contracts/dummy.sol") }
    subject(:test_contract) { Eth::Contract.create(file: "spec/fixtures/contracts/simple_registry.sol") }

    it "call function name" do
      geth_dev_http.deploy_and_wait(contract)
      result = geth_dev_http.call(contract, "get")
      expect(result).to eq(0)
    end

    it "called function name not defined" do
      expect { geth_dev_http.call(contract, "ge") }.to raise_error ArgumentError
    end

    it "call the function with key" do
      geth_dev_http.deploy_and_wait(contract)
      result = geth_dev_http.call(contract, "get", sender_key: test_key)
      expect(result).to eq(0)
    end

    it "call the function using legacy transactions" do
      geth_dev_http.deploy_and_wait(contract)
      result = geth_dev_http.call(contract, "get", legacy: true)
      expect(result).to eq(0)
    end

    it "processing when two numbers are returned" do
      address = geth_dev_http.deploy_and_wait(test_contract)
      response = geth_dev_http.call(test_contract, "get")
      expect(response).to eq([0, 0])
      geth_dev_http.transact_and_wait(test_contract, "set", 12, 24, address: address)
      response = geth_dev_http.call(test_contract, "get")
      expect(response).to eq([12, 24])
    end
  end

  describe ".transact .transact_and_wait" do
    subject(:test_key) { Key.new }
    subject(:contract) { Eth::Contract.create(file: "spec/fixtures/contracts/dummy.sol") }

    it "the value can be set with the set function" do
      address = geth_dev_http.deploy_and_wait(contract)
      response = geth_dev_http.call(contract, "get")
      expect(response).to eq(0)
      geth_dev_http.transact_and_wait(contract, "set", 42, address: address)
      response = geth_dev_http.call(contract, "get")
      expect(response).to eq(42)
    end

    it "transact the function with key" do
      geth_dev_http.transfer_and_wait(test_key.address, 1337 * Unit::ETHER)
      address = geth_dev_http.deploy_and_wait(contract, sender_key: test_key)
      response = geth_dev_http.transact_and_wait(contract, "set", 42, sender_key: test_key, address: address)
      expect(response).to start_with "0x"
    end

    it "transact the function using legacy transactions" do
      address = geth_dev_http.deploy_and_wait(contract)
      response = geth_dev_http.transact_and_wait(contract, "set", 42, legacy: true, address: address)
      expect(response).to start_with "0x"
    end
  end

  describe ".is_valid_signature" do
    subject(:key) { Key.new priv: "8387af3ab105157d8fcdefdb41ef12aaa876c5123e2c57c9640dcdd74157b3b4" }
    subject(:contract) { Contract.create(file: "spec/fixtures/contracts/signer.sol", contract_index: 1) }
    let(:magic) { "1626ba7e" }

    it "has a valid eip1271 interface" do
      expect(contract.functions[0].name).to eq "isValidSignature"
      expect(contract.functions[0].signature).to eq magic
    end

    it "can recover a valid signature from smart contract" do
      expect(key.address.to_s).to eq "0xd5732335EB868F17B750B29fF4097987DF8D0D35"
      msg = "I am authentic!"
      prefixed = Signature.prefix_message msg
      hashed = Util.keccak256 prefixed
      expect(Util.bin_to_hex hashed).to eq "70fbc577c8e07a6fd0217225d87f638b7ed26e2f5212931d49d324da07f31df2"
      signature = key.sign hashed
      expect(signature).to eq "2166d149f4cddd5cf0e8f165366322a3fce0d05e82269371477199f12160c72c0de17dea759a80e2c40334903a2ec5b7d53ba47e0eb9d8dd996a921e811a58a61c"
      signature = Util.hex_to_bin signature
      expect { geth_dev_ipc.is_valid_signature(contract, hashed, signature) }.to raise_error ArgumentError, "Contract not deployed yet."
      geth_dev_ipc.deploy_and_wait(contract)
      expect(geth_dev_ipc.is_valid_signature(contract, hashed, signature)).to be true
    end
  end
end
