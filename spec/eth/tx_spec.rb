require "spec_helper"

describe Eth::Tx do
  describe "#GAS" do
    it "defines gas limits" do
      expect(Eth::Tx::DEFAULT_LIMIT).to eq 21_000
      expect(Eth::Tx::BLOCK_LIMIT).to eq 10_000_000
    end
  end
end
