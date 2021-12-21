require "spec_helper"

describe Eth::Unit do
  describe "#ETHER" do
    it "has constants for all common Ether units" do
      expect(Eth::Unit::WEI).to eq 1
      expect(Eth::Unit::BABBAGE).to eq 1_000
      expect(Eth::Unit::LOVELACE).to eq 1_000_000
      expect(Eth::Unit::SHANNON).to eq 1_000_000_000
      expect(Eth::Unit::SZABO).to eq 1_000_000_000_000
      expect(Eth::Unit::FINNEY).to eq 1_000_000_000_000_000
      expect(Eth::Unit::ETHER).to eq 1_000_000_000_000_000_000
      expect(Eth::Unit::GWEI).to eq 1_000_000_000
    end
  end
end
