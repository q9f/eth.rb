# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Parser do
  context "abicoder tests" do
    it "test_base" do
      type = Abi::Parser.parse("uint256")
      expect(type.format).to eq "uint256"
    end
  end
end
