require "spec_helper"

describe Contract do
  subject(:solc) { Eth::Solidity.new }
  subject(:contract) { solc.compile(file) }
  subject(:dummy_contract) { Contract.new(name, bin, abi) }

  let(:file) { "spec/fixtures/contracts/dummy.sol" }
  let(:name) { contract.keys[0] }
  let(:bin) { contract[name]["bin"] }
  let(:abi) { contract[name]["abi"] }

  describe ".initialize" do
    it "Dummy contract initialized" do
      expect(dummy_contract).to be_instance_of(Contract)
    end
  end

  describe "address=" do
    it "set valid address" do
      dummy_contract.address = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
      expect(dummy_contract.address).to eq "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
    end

    it "invalid address cannot be set" do
      expect { dummy_contract.address = "0x1" }.to raise_error Address::CheckSumError
    end
  end

  describe ".create" do
    it "create contract from file" do
      contract = Contract.create(file: file)
      expect(contract).to be_instance_of(Eth::Contract::Dummy)
    end

    it "create contract from abi" do
      contract = Contract.create(name: name, abi: abi, bin: bin)
      expect(contract).to be_instance_of(Eth::Contract::Dummy)
    end

    it "arguments are missing" do
      expect { Contract.create(name: name, abi: abi) }.to raise_error ArgumentError
    end

    it "invalid abi json parsing fails" do
      abi = abi.to_json + '"'
      expect { Contract.create(name: name, abi: abi, bin: bin) }.to raise_error JSON::ParserError
    end

    it "contact index can be specified" do
      file = "spec/fixtures/contracts/greeter.sol"
      greeter = Contract.create(file: file, contract_index: 0)
      expect(greeter).to be_instance_of(Eth::Contract::Greeter)
      mortal = Contract.create(file: file, contract_index: 1)
      expect(mortal).to be_instance_of(Eth::Contract::Mortal)
    end
  end
end
