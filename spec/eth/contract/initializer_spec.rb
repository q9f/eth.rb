require "spec_helper"

describe Contract::Initializer do
  subject(:file) { "spec/fixtures/contracts/greeter.sol" }
  subject(:contract_initializer) { Contract::Initializer.new(file) }

  describe ".initialize" do
    it "contracts initialized" do
      expect(contract_initializer.contracts.size).to eq 2
      expect(contract_initializer.contracts.first).to be_instance_of(Contract)
    end
  end

  describe ".build_all" do
    it "build all contracts " do
      contracts = contract_initializer.build_all
      expect(contracts.size).to eq 2
      expect(contracts[0].class_object).to eq(Eth::Contract::Greeter)
      expect(contracts[1].class_object).to eq(Eth::Contract::Mortal)
    end
  end
end
