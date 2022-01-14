require "spec_helper"

describe Unit do
  context "#ETHER" do
    it "has constants for all common Ether units" do
      expect(Unit::WEI).to eq 1
      expect(Unit::BABBAGE).to eq 1_000
      expect(Unit::LOVELACE).to eq 1_000_000
      expect(Unit::SHANNON).to eq 1_000_000_000
      expect(Unit::SZABO).to eq 1_000_000_000_000
      expect(Unit::FINNEY).to eq 1_000_000_000_000_000
      expect(Unit::ETHER).to eq 1_000_000_000_000_000_000
      expect(Unit::GWEI).to eq 1_000_000_000
    end
  end
end
