require "spec_helper"

describe Contract do
  describe ".initialize" do
    subject(:solc) { Eth::Solidity.new }
    subject(:contract) { solc.compile "spec/fixtures/contracts/dummy.sol" }

    it "Dummy contract initialized" do
      name = contract.keys[0]
      bin = contract[name]["bin"]
      abi = contract[name]["abi"]

      expect(Contract.new(name, bin, abi)).to be_instance_of(Contract)
    end
  end
end
