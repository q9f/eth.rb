require "spec_helper"

describe Contract do
  subject(:solc) { Eth::Solidity.new }
  subject(:contract) { solc.compile(file) }
  subject(:dummy_contract) { Contract.new(name, bin, abi) }

  let(:file) { "spec/fixtures/contracts/dummy.sol" }
  let(:name) { contract.keys[0] }
  let(:bin) { contract[name]["bin"] }
  let(:abi) { contract[name]["abi"] }
  let(:addr) { "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed" }

  describe ".initialize" do
    it "Dummy contract initialized" do
      expect(dummy_contract).to be_instance_of(Contract)
    end
  end

  describe "address=" do
    it "set valid address" do
      dummy_contract.address = Eth::Address.new addr
      expect(dummy_contract.address).to eq addr
    end

    it "invalid address cannot be set" do
      expect { dummy_contract.address = "0x1" }.to raise_error Address::CheckSumError
    end
  end

  describe ".from_file .from_bin .from_abi" do
    it "create contract from file" do
      contract = Contract.from_file(file: file)
      expect(contract.address).to be nil
      expect(contract).to be_instance_of(Eth::Contract::Dummy)
    end

    it "create contract from binary" do
      contract = Contract.from_bin(name: name, abi: abi, bin: bin)
      expect(contract).to be_instance_of(Eth::Contract::Dummy)
    end

    it "create contract from abi" do
      contract = Contract.from_abi(name: name, abi: abi, address: addr)
      expect(contract).to be_instance_of(Eth::Contract::Dummy)
      expect(contract.address).to eq addr
    end

    it "arguments are missing" do
      expect { Contract.from_file() }.to raise_error ArgumentError, "Cannot find the contract at !"
      expect { Contract.from_abi(name: name, address: addr) }.to raise_error ArgumentError, "Address, ABI, and contract name are required!"
      expect { Contract.from_bin(name: name, abi: abi) }.to raise_error ArgumentError, "ABI, binary, and contract name are required!"
    end

    it "invalid abi json parsing fails" do
      abi = abi.to_json + '"'
      expect { Contract.from_abi(name: name, abi: abi, address: addr) }.to raise_error JSON::ParserError
      expect { Contract.from_bin(name: name, abi: abi, bin: bin) }.to raise_error JSON::ParserError
    end

    it "contact index can be specified" do
      file = "spec/fixtures/contracts/greeter.sol"
      greeter = Contract.from_file(file: file, contract_index: 0)
      expect(greeter).to be_instance_of(Eth::Contract::Greeter)
      mortal = Contract.from_file(file: file, contract_index: 1)
      expect(mortal).to be_instance_of(Eth::Contract::Mortal)
    end
  end
end
