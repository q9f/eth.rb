require "spec_helper"

describe Contract::Event do
  let(:path) { "spec/fixtures/contracts/test_contract.sol" }
  subject(:contract) { Eth::Contract.from_file(file: path) }

  context ".initialize" do
    it "succeed" do
      expect(contract.events[0].name).to eq("changed")
      expect(contract.events[0].signature).to eq("0d3a6aeecf5d29a90d2c145270bd1b2554069d03e76c09a660b27ccd165c2c42")
      expect(contract.events[0].event_string).to eq("changed()")
      expect(contract.events[1].name).to eq("killed")
      expect(contract.events[1].signature).to eq("1f3a0e41bf4d8306f04763663bf025d1824a391571ce3a07186a195f8c4cfd3c")
      expect(contract.events[1].event_string).to eq("killed()")
    end
  end
end
