require "spec_helper"

# run `geth --dev --http --ipcpath /tmp/geth.ipc`
# to provide both http and ipc to pass these tests.

describe Client do
  let(:geth_dev_ipc_path) { "/tmp/geth.ipc" }
  let(:geth_dev_http_path) { "http://127.0.0.1:8545" }
  let(:geth_dev_http_basic_auth_path) { "http://username:password@127.0.0.1:8545" }
  subject(:geth_dev_ipc) { Client.create geth_dev_ipc_path }
  subject(:geth_dev_http) { Client.create geth_dev_http_path }
  subject(:geth_dev_http_auth) { Client.create geth_dev_http_basic_auth_path }

  describe ".create .initialize" do
    it "creates an ipc client" do
      expect(geth_dev_ipc).to be
      expect(geth_dev_ipc).to be_instance_of Client::Ipc
      expect(geth_dev_ipc.path).to eq geth_dev_ipc_path
    end

    it "creates an http client" do
      expect(geth_dev_http).to be
      expect(geth_dev_http).to be_instance_of Client::Http
      expect(geth_dev_http.host).to eq "127.0.0.1"
      expect(geth_dev_http.port).to eq 8545
      expect(geth_dev_http.uri.to_s).to eq geth_dev_http_path
      expect(geth_dev_http.ssl).to be_falsy
    end

    it "creates a http basic auth client" do
      expect(geth_dev_http_auth).to be
      expect(geth_dev_http_auth).to be_instance_of Client::HttpAuth
      expect(geth_dev_http_auth.host).to eq "127.0.0.1"
      expect(geth_dev_http_auth.port).to eq 8545
      expect(geth_dev_http_auth.uri.to_s).to eq geth_dev_http_basic_auth_path
      expect(geth_dev_http_auth.user).to eq "username"
      expect(geth_dev_http_auth.instance_variable_get(:@password)).to eq "password"
      expect(geth_dev_http_auth.ssl).to be_falsy
    end

    it "functions as geth development client" do
      expect(geth_dev_ipc.id).to eq 0
      expect(geth_dev_ipc.chain_id).to eq Chain::PRIVATE_GETH
      expect(geth_dev_ipc.default_account).to be_instance_of Address
      expect(geth_dev_ipc.max_priority_fee_per_gas).to eq Tx::DEFAULT_PRIORITY_FEE
      expect(geth_dev_ipc.max_fee_per_gas).to eq Tx::DEFAULT_GAS_PRICE
      expect(geth_dev_ipc.gas_limit).to eq Tx::DEFAULT_GAS_LIMIT
    end

    it "http can query basic methods" do

      # the default account is prefunded; this test fails if you manually drain the account to zero
      expect(geth_dev_http.get_balance geth_dev_http.default_account).to be > 0
      expect(geth_dev_http.get_nonce geth_dev_http.default_account).to be >= 0
      expect(geth_dev_http.reset_id).to eq 0
    end

    it "http basic auth can query basic methods" do

      # the default account is prefunded; this test fails if you manually drain the account to zero
      expect(geth_dev_http_auth.get_balance geth_dev_http.default_account).to be > 0
      expect(geth_dev_http_auth.get_nonce geth_dev_http.default_account).to be >= 0
      expect(geth_dev_http_auth.reset_id).to eq 0
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
    subject(:contract) { Eth::Contract.from_file(file: "spec/fixtures/contracts/dummy.sol") }
    subject(:test_key) { Key.new }
    let(:ens_registry_bin) { File.read "spec/fixtures/bin/ENSRegistryWithFallback.bin", :encoding => "ascii-8bit" }
    let(:ens_registry_abi) { File.read "spec/fixtures/abi/ENSRegistryWithFallback.json", :encoding => "ascii-8bit" }

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

    it "deploys the contract with a gas limit override" do
      address = geth_dev_http.deploy_and_wait(contract, gasLimit: 1_000_000)
      expect(address).to start_with "0x"
    end

    it "deploy the contract with constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_dev_http.deploy_and_wait(contract, "Hello!")
      expect(address).to start_with "0x"
    end

    it "can deploy and call an ens registry" do
      require 'byebug'
      ens_registry = Contract.from_bin(bin: ens_registry_bin.strip, abi: ens_registry_abi.strip, name: "ENSRegistryWithFallback")
      ens_address = geth_dev_ipc.deploy_and_wait(ens_registry, "0x112234455c3a32fd11230c42e7bccd4a84e02010")
      expect(ens_registry).to be_instance_of(Eth::Contract::ENSRegistryWithFallback)
      expect(ens_registry.address).to eq Address.new(ens_address).to_s
      expect(geth_dev_ipc.call(ens_registry, "old")).to eq "0x112234455c3a32fd11230c42e7bccd4a84e02010"
    end
  end

  describe ".call" do
    subject(:test_key) { Key.new }
    subject(:contract) { Eth::Contract.from_file(file: "spec/fixtures/contracts/dummy.sol") }
    subject(:test_contract) { Eth::Contract.from_file(file: "spec/fixtures/contracts/simple_registry.sol") }
    let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
    let(:address) { Eth::Address.new("0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9").address }
    subject(:erc20_abi) { JSON.parse erc20_abi_file }
    subject(:erc20_contract) { Eth::Contract.from_abi(abi: erc20_abi, name: "ERC20", address: address) }

    it "call function name" do
      geth_dev_http.deploy_and_wait(contract)
      result = geth_dev_http.call(contract, "get")
      expect(result).to eq(0)
    end

    it "calls a function with gas_limit override" do
      geth_dev_http.deploy_and_wait(contract)
      result = geth_dev_http.call(contract, "get", gasLimit: 60_000)
      expect(result).to eq(0)
    end

    it "return nil if raw result is 0x" do
      expect(geth_dev_http.call(erc20_contract, "balanceOf", address)).to be_nil
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

    it "transacts with gas limit override" do
      address = geth_dev_http.deploy_and_wait(test_contract)
      txn_hash = geth_dev_http.transact_and_wait(test_contract, "set", 12, 24, address: address, gasLimit: 100_000_000)
      response = geth_dev_http.eth_get_transaction_by_hash(txn_hash)
      response = geth_dev_http.call(test_contract, "get")
      expect(response).to eq([12, 24])
    end

    it "calls the function with constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_dev_http.deploy_and_wait(contract, "Hello!")
      result = geth_dev_http.call(contract, "greet", address: address)
      expect(result).to eq("Hello!")
    end
  end

  describe ".transact .transact_and_wait" do
    subject(:test_key) { Key.new }
    subject(:contract) { Eth::Contract.from_file(file: "spec/fixtures/contracts/dummy.sol") }

    it "the value can be set with the set function" do
      address = geth_dev_http.deploy_and_wait(contract)
      response = geth_dev_http.call(contract, "get")
      expect(response).to eq(0)
      geth_dev_http.transact_and_wait(contract, "set", 42, address: address)
      response = geth_dev_http.call(contract, "get")
      expect(response).to eq(42)
    end

    it "the value can be set with the set function, overwriting constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_dev_http.deploy_and_wait(contract, "Hello!")
      geth_dev_http.transact_and_wait(contract, "setGreeting", "How are you?", address: address)
      response = geth_dev_http.call(contract, "greet")
      expect(response).to eq("How are you?")
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

    it "transacts the function with constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_dev_http.deploy_and_wait(contract, "Hello!")
      response = geth_dev_http.transact_and_wait(contract, "setGreeting", "How are you?", address: address)
      expect(response).to start_with "0x"
    end
  end

  describe ".is_valid_signature" do
    subject(:key) { Key.new priv: "8387af3ab105157d8fcdefdb41ef12aaa876c5123e2c57c9640dcdd74157b3b4" }
    subject(:contract) { Contract.from_file(file: "spec/fixtures/contracts/signer.sol", contract_index: 1) }
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
