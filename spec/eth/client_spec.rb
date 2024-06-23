require "spec_helper"

describe Client do

  # run `geth --dev --http --ipcpath /tmp/geth.ipc`
  # to provide both http and ipc to pass these tests.
  let(:geth_ipc_path) { "/tmp/geth.ipc" }
  let(:geth_http_path) { "http://127.0.0.1:8545" }
  let(:geth_http_authed_path) { "http://username:password@127.0.0.1:8545" }
  subject(:geth_ipc) { Client.create geth_ipc_path }
  subject(:geth_http) { Client.create geth_http_path }
  subject(:geth_http_authed) { Client.create geth_http_authed_path }

  # it expects an $INFURA_TOKEN in environment
  let(:infura_api) { "https://mainnet.infura.io/v3/#{ENV["INFURA_TOKEN"]}" }
  subject(:infura_mainnet) { Client.create infura_api }

  describe ".create .initialize" do
    it "creates an ipc client" do
      expect(geth_ipc).to be
      expect(geth_ipc).to be_instance_of Client::Ipc
      expect(geth_ipc.path).to eq geth_ipc_path
    end

    it "creates an http client" do
      expect(geth_http).to be
      expect(geth_http).to be_instance_of Client::Http
      expect(geth_http.host).to eq "127.0.0.1"
      expect(geth_http.port).to eq 8545
      expect(geth_http.uri.to_s).to eq geth_http_path
      expect(geth_http.ssl).to be_falsy
    end

    it "connects to an infura api" do
      expect(infura_mainnet).to be
      expect(infura_mainnet).to be_instance_of Client::Http
      expect(infura_mainnet.ssl).to be_truthy
      expect(infura_mainnet.chain_id).to eq Chain::ETHEREUM
    end

    it "does not query remote accounts" do
      expect { infura_mainnet.default_account }.to raise_error ArgumentError, "The default account is not available on remote connections!"
      expect(geth_http.default_account).to be
    end

    it "creates a http basic auth client" do
      expect(geth_http_authed).to be
      expect(geth_http_authed).to be_instance_of Client::Http
      expect(geth_http_authed.host).to eq "127.0.0.1"
      expect(geth_http_authed.port).to eq 8545
      expect(geth_http_authed.uri.to_s).to eq geth_http_authed_path
      expect(geth_http_authed.user).to eq "username"
      expect(geth_http_authed.instance_variable_get(:@password)).to eq "password"
      expect(geth_http_authed.ssl).to be_falsy
    end

    it "functions as geth development client" do
      expect(geth_ipc.id).to eq 0
      expect(geth_ipc.chain_id).to eq Chain::PRIVATE_GETH
      expect(geth_ipc.default_account).to be_instance_of Address
      expect(geth_ipc.max_priority_fee_per_gas).to eq Tx::DEFAULT_PRIORITY_FEE
      expect(geth_ipc.max_fee_per_gas).to eq Tx::DEFAULT_GAS_PRICE
    end

    it "http can query basic methods" do

      # the default account is prefunded; this test fails if you manually drain the account to zero
      expect(geth_http.get_balance geth_http.default_account).to be > 0
      expect(geth_http.get_nonce geth_http.default_account).to be >= 0
      expect(geth_http.reset_id).to eq 0
    end

    it "http basic auth can query basic methods" do

      # the default account is prefunded; this test fails if you manually drain the account to zero
      expect(geth_http_authed.get_balance geth_http.default_account).to be > 0
      expect(geth_http_authed.get_nonce geth_http.default_account).to be >= 0
      expect(geth_http_authed.reset_id).to eq 0
    end

    it "does not create dysfunctional clients" do
      expect { Client.create "ftp://127.0.0.1:8545" }.to raise_error ArgumentError, "Unable to detect client type!"
      expect { Client.create "/home/user/fun.txt" }.to raise_error ArgumentError, "Unable to detect client type!"
    end
  end

  describe "ens" do
    it "can resolve an ens record" do
      expect(infura_mainnet.resolve_ens("ncwc6edqldzy6mlo.eth")).to eq "0xde270e46d63b1816d1b798cff473c4ba238aca73"
    end
  end

  describe ".transfer .transfer_and_wait" do
    subject(:test_key) { Key.new }
    subject(:another_key) { Key.new }

    it "funds a random account and returns the money" do
      geth_http.transfer_and_wait(test_key.address, 1337 * Unit::ETHER)
      expect(geth_http.get_balance test_key.address).to eq 1337 * Unit::ETHER
      geth_ipc.transfer_and_wait(geth_ipc.default_account, 42 * Unit::ETHER, sender_key: test_key)
      expect(geth_ipc.get_nonce test_key.address).to eq 1
    end

    it "funds a random account using legacy transactions" do
      geth_http.transfer_and_wait(another_key.address, 69 * Unit::ETHER, legacy: true)
      expect(geth_http.get_balance another_key.address).to eq 69 * Unit::ETHER
      geth_ipc.transfer_and_wait(geth_ipc.default_account, 23 * Unit::ETHER, sender_key: another_key, legacy: true)
      expect(geth_ipc.get_nonce another_key.address).to eq 1
    end

    context "when nonce manually set" do
      it "raises exception when nonce incorrect" do
        expect {
          geth_http.transfer(another_key.address, 69 * Unit::ETHER, legacy: true, nonce: 0)
        }.to raise_error(IOError, /nonce too low: next nonce [0-9]+, tx nonce [0-9]+/)
      end

      it "funds account twice" do
        inblock_account_nonce = geth_http.get_nonce(geth_http.default_account)

        geth_http.transfer(another_key.address, 69 * Unit::ETHER, legacy: true, nonce: inblock_account_nonce)
        inblock_account_nonce += 1

        geth_http.transfer_and_wait(another_key.address, 69 * Unit::ETHER, legacy: true, nonce: inblock_account_nonce)
        inblock_account_nonce += 1

        expect(inblock_account_nonce).to eq(geth_http.get_nonce(geth_http.default_account))
      end
    end
  end

  describe ".deploy .deploy_and_wait" do
    subject(:contract) { Eth::Contract.from_file(file: "spec/fixtures/contracts/dummy.sol") }
    subject(:test_key) { Key.new }
    let(:ens_registry_bin) { File.read "spec/fixtures/bin/ENSRegistryWithFallback.bin", :encoding => "ascii-8bit" }
    let(:ens_registry_abi) { File.read "spec/fixtures/abi/ENSRegistryWithFallback.json", :encoding => "ascii-8bit" }

    it "deploy the contract and the address is returned" do
      address = geth_http.deploy_and_wait(contract)
      expect(address).to start_with "0x"
      expect(address.length).to eq 42
      address = geth_ipc.deploy_and_wait(contract)
      expect(address).to start_with "0x"
      expect(address.length).to eq 42
    end

    it "deploy the contract with key" do
      geth_http.transfer_and_wait(test_key.address, 1337 * Unit::ETHER)
      address = geth_http.deploy_and_wait(contract, sender_key: test_key)
      expect(address).to start_with "0x"
    end

    it "deploy the contract using legacy transactions" do
      address = geth_http.deploy_and_wait(contract, legacy: true)
      expect(address).to start_with "0x"
    end

    it "deploys the contract with a gas limit override" do
      address = geth_http.deploy_and_wait(contract, gas_limit: 1_000_000)
      expect(address).to start_with "0x"
    end

    it "deploy the contract with constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_http.deploy_and_wait(contract, "Hello!")
      expect(address).to start_with "0x"
    end

    it "can deploy and call an ens registry" do
      ens_registry = Contract.from_bin(bin: ens_registry_bin.strip, abi: ens_registry_abi.strip, name: "ENSRegistryWithFallback")
      ens_address = geth_ipc.deploy_and_wait(ens_registry, "0x112234455c3a32fd11230c42e7bccd4a84e02010")
      expect(ens_registry).to be_instance_of(Eth::Contract::ENSRegistryWithFallback)
      expect(ens_registry.address).to eq Address.new(ens_address).to_s
      expect(geth_ipc.call(ens_registry, "old")).to eq "0x112234455c3a32fd11230c42e7bccd4a84e02010"
    end

    context "when nonce manually set" do
      it "raises exception when nonce incorrect" do
        expect {
          geth_http.deploy_and_wait(contract, nonce: 0)
        }.to raise_error(IOError, /nonce too low: next nonce [0-9]+, tx nonce [0-9]+/)
      end

      it "deploys the contract twice" do
        inblock_account_nonce = geth_http.get_nonce(geth_http.default_account)

        geth_http.deploy(contract, nonce: inblock_account_nonce)
        inblock_account_nonce += 1

        geth_http.deploy_and_wait(contract, nonce: inblock_account_nonce)
        inblock_account_nonce += 1

        expect(inblock_account_nonce).to eq(geth_http.get_nonce(geth_http.default_account))
      end
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
      geth_http.deploy_and_wait(contract)
      result = geth_http.call(contract, "get")
      expect(result).to eq(0)
    end

    it "calls a function with gas_limit override" do
      geth_http.deploy_and_wait(contract)
      result = geth_http.call(contract, "get", gas_limit: 60_000)
      expect(result).to eq(0)
    end

    it "return nil if raw result is 0x" do
      expect(geth_http.call(erc20_contract, "balanceOf", address)).to be_nil
    end

    it "allows to call client with custom block numberreturn nil if raw result is 0x" do
      block_number = 123

      geth_http.block_number = block_number

      expected_payload = {
        jsonrpc: "2.0",
        method: "eth_call",
        params: [{
          data: "0x70a08231000000000000000000000000d496b23d61f88a8c7758fca7560dcfac7b3b01f9",
          to: "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
        }, "0x#{block_number.to_s(16)}"],
        id: 1
      }.to_json

      mock_response = {
        jsonrpc: "2.0",
        id: 1,
        result: "0x0000000000000000000000000000000000000000000000000000000000000000"
      }

      expect_any_instance_of(Eth::Client::Http)
        .to receive(:send_request)
              .with(expected_payload)
              .and_return(mock_response.to_json)

      geth_http.call(erc20_contract, "balanceOf", address)
    end

    it "called function name not defined" do
      expect {
        geth_http.call(contract, "ge")
      }.to raise_error ArgumentError, "this function does not exist!"
    end

    it "call the function with key" do
      geth_http.deploy_and_wait(contract)
      result = geth_http.call(contract, "get", sender_key: test_key)
      expect(result).to eq(0)
    end

    it "call the function using legacy transactions" do
      geth_http.deploy_and_wait(contract)
      result = geth_http.call(contract, "get", legacy: true)
      expect(result).to eq(0)
    end

    it "processing when two numbers are returned" do
      address = geth_http.deploy_and_wait(test_contract)
      response = geth_http.call(test_contract, "get")
      expect(response).to eq([0, 0])
      geth_http.transact_and_wait(test_contract, "set", 12, 24, address: address)
      response = geth_http.call(test_contract, "get")
      expect(response).to eq([12, 24])
    end

    it "transacts with gas limit override" do
      address = geth_http.deploy_and_wait(test_contract)
      txn_hash = geth_http.transact_and_wait(test_contract, "set", 12, 24, address: address, gas_limit: 100_000_000)
      response = geth_http.eth_get_transaction_by_hash(txn_hash)
      response = geth_http.call(test_contract, "get")
      expect(response).to eq([12, 24])
    end

    it "calls the function with constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_http.deploy_and_wait(contract, "Hello!")
      result = geth_http.call(contract, "greet", address: address)
      expect(result).to eq("Hello!")
    end
  end

  describe ".transact .transact_and_wait" do
    subject(:test_key) { Key.new }
    subject(:contract) { Eth::Contract.from_file(file: "spec/fixtures/contracts/dummy.sol") }

    it "the value can be set with the set function" do
      address = geth_http.deploy_and_wait(contract)
      response = geth_http.call(contract, "get")
      expect(response).to eq(0)
      geth_http.transact_and_wait(contract, "set", 42, address: address)
      response = geth_http.call(contract, "get")
      expect(response).to eq(42)
    end

    it "the value can be set with the set function, overwriting constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_http.deploy_and_wait(contract, "Hello!")
      geth_http.transact_and_wait(contract, "setGreeting", "How are you?", address: address)
      response = geth_http.call(contract, "greet")
      expect(response).to eq("How are you?")
    end

    it "transact the function with key" do
      geth_http.transfer_and_wait(test_key.address, 1337 * Unit::ETHER)
      address = geth_http.deploy_and_wait(contract, sender_key: test_key)
      response = geth_http.transact_and_wait(contract, "set", 42, sender_key: test_key, address: address)
      expect(response).to start_with "0x"
    end

    it "transact the function using legacy transactions" do
      address = geth_http.deploy_and_wait(contract)
      response = geth_http.transact_and_wait(contract, "set", 42, legacy: true, address: address)
      expect(response).to start_with "0x"
    end

    it "transacts the function with constructor params" do
      contract = Contract.from_file(file: "spec/fixtures/contracts/greeter.sol", contract_index: 0)
      address = geth_http.deploy_and_wait(contract, "Hello!")
      response = geth_http.transact_and_wait(contract, "setGreeting", "How are you?", address: address)
      expect(response).to start_with "0x"
    end

    it "transacts the function with specific tx value argument" do
      geth_http.transfer_and_wait(test_key.address, 0.01 * Unit::ETHER)
      address = geth_http.deploy_and_wait(contract, sender_key: test_key)
      tx_value = 1
      tx_hash = geth_http.transact_and_wait(contract, "set", 42, sender_key: test_key, address: address, tx_value: tx_value)
      tx_value_from_server = geth_http.eth_get_transaction_by_hash(tx_hash)["result"]["value"].to_i(16)
      expect(tx_value_from_server).to eq(tx_value)
    end

    it "can determine if a transaction is mined or succeeded" do
      hash = geth_http.deploy(contract)
      hash = geth_http.wait_for_tx(hash)
      expect(geth_http.tx_mined? hash).to be_truthy
      addr = geth_http.eth_get_transaction_receipt(hash)["result"]["contractAddress"]
      hash = geth_http.transact(contract, "set", 42, address: addr)
      hash = geth_http.wait_for_tx(hash)
      expect(geth_http.tx_mined? hash).to be_truthy
      expect(geth_http.tx_succeeded? hash).to be_truthy
    end

    it "raises if a transaction fails" do
      addr = geth_http.deploy_and_wait(contract)
      hash = geth_http.transact_and_wait(contract, "set", 42, address: addr)
      expect(geth_http.tx_mined? hash).to be_truthy
      expect(geth_http.tx_succeeded? hash).to be_truthy
      expect {
        hash = geth_http.transact_and_wait(contract, "set", 138, address: addr)
      }.to raise_error(Client::ContractExecutionError, "execution reverted")
    end

    context "when nonce manually set" do
      let(:contract_address) { geth_http.deploy_and_wait(contract) }

      it "raises exception when nonce incorrect" do
        expect {
          geth_http.transact(contract, "set", 42, address: contract_address, nonce: 0)
        }.to raise_error(IOError, /nonce too low: next nonce [0-9]+, tx nonce [0-9]+/)
      end

      it "transacts function twice" do
        contract_address
        inblock_account_nonce = geth_http.get_nonce(geth_http.default_account)

        geth_http.transact(contract, "set", 42, address: contract_address, nonce: inblock_account_nonce)
        inblock_account_nonce += 1

        geth_http.transact(contract, "set", 43, address: contract_address, nonce: inblock_account_nonce)
        inblock_account_nonce += 1

        expect(inblock_account_nonce).to eq(geth_http.get_nonce(geth_http.default_account))
      end

      it "does not mutate marshalled objects" do
        params = {
          from: geth_http.default_account,
          value: 101,
        }
        geth_http.eth_estimate_gas(params)
        expect(params.dig(:value)).to eq 101
      end
    end
  end

  describe ".transfer_erc20 .transfer_erc20_and_wait" do
    subject(:key) { Key.new }
    subject(:erc20) { Eth::Contract.from_file(file: "spec/fixtures/contracts/erc20.sol") }

    it "deploys and mints erc20 tokens" do
      geth_ipc.transfer_and_wait(key.address, Unit::ETHER)
      geth_ipc.deploy_and_wait(erc20, "FooBarBaz Token", "FOO")
      expect(geth_ipc.call(erc20, "name")).to eq "FooBarBaz Token"
      expect(geth_ipc.call(erc20, "symbol")).to eq "FOO"
      expect(geth_ipc.call(erc20, "decimals")).to eq 18
      geth_ipc.transact_and_wait(erc20, "mint", key.address.to_s, Unit::ETHER)
      expect(geth_ipc.call(erc20, "balanceOf", key.address.to_s)).to eq Unit::ETHER
      expect(geth_ipc.call(erc20, "totalSupply")).to eq Unit::ETHER
    end

    it "transfers erc20 tokens" do
      geth_ipc.transfer_and_wait(key.address, Unit::ETHER)
      geth_ipc.deploy_and_wait(erc20, "FooBarBaz Token", "FOO")
      geth_ipc.transact_and_wait(erc20, "mint", geth_ipc.default_account.to_s, Unit::ETHER)
      geth_ipc.transfer_erc20_and_wait(erc20, key.address.to_s, 17)
      expect(geth_ipc.call(erc20, "balanceOf", key.address.to_s)).to eq 17
      expect(geth_ipc.call(erc20, "balanceOf", geth_ipc.default_account.to_s)).to eq Unit::ETHER - 17
      expect(geth_ipc.call(erc20, "totalSupply")).to eq Unit::ETHER
      tx = geth_ipc.transact(erc20, "mint", key.address.to_s, Unit::ETHER, sender_key: key)
      geth_ipc.wait_for_tx(tx)
      tf = geth_ipc.transfer_erc20(erc20, geth_ipc.default_account.to_s, 17, sender_key: key)
      geth_ipc.wait_for_tx(tf)
      expect(geth_ipc.call(erc20, "balanceOf", key.address.to_s)).to eq Unit::ETHER
      expect(geth_ipc.call(erc20, "balanceOf", geth_ipc.default_account.to_s)).to eq Unit::ETHER
      expect(geth_ipc.call(erc20, "totalSupply")).to eq 2 * Unit::ETHER
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
      expect { geth_ipc.is_valid_signature(contract, hashed, signature) }.to raise_error ArgumentError, "Contract not deployed yet."
      geth_ipc.deploy_and_wait(contract)
      expect(geth_ipc.is_valid_signature(contract, hashed, signature)).to be true
    end
  end
end
