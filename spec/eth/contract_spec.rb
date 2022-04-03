require "spec_helper"

describe Contract do
  subject(:solc) { Eth::Solidity.new }
  subject(:contract) { solc.compile "spec/fixtures/contracts/dummy.sol" }

  let(:name) { contract.keys[0] }
  let(:bin) { contract[name]["bin"] }
  let(:abi) { contract[name]["abi"] }

  describe ".initialize" do
    it "Dummy contract initialized" do
      expect(Contract.new(name, bin, abi)).to be_instance_of(Contract)
    end
  end

  describe "address=" do
    it "set valid address" do
      dummy_contract = Contract.new(name, bin, abi)
      dummy_contract.address = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
      expect(dummy_contract.address).to eq "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
    end

    it "invalid address cannot be set" do
      dummy_contract = Contract.new(name, bin, abi)
      expect { dummy_contract.address = "0x1" }.to raise_error Address::CheckSumError
    end
  end
end
