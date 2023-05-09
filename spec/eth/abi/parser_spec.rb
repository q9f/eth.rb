# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Parser do
  it "parses dimensions" do
    expect(Abi::Parser.parse_dimension("uint256")).to eq []
    expect(Abi::Parser.parse_dimension("uint256[]")).to eq [-1]
    expect(Abi::Parser.parse_dimension("uint256[0]")).to eq [0]
    expect(Abi::Parser.parse_dimension("uint256[7]")).to eq [7]
  end

  context "abicoder tests" do
    it "test_base" do
      type = Abi::Parser.parse("uint256")
      expect(type.format).to eq "uint256"
      base_type = Abi::Parser.parse_base_type("uint256")
      expect(base_type).to eq ["uint", 256, []]

      type = Abi::Parser.parse("uint8")
      expect(type.format).to eq "uint8"
      base_type = Abi::Parser.parse_base_type("uint8")
      expect(base_type).to eq ["uint", 8, []]

      type = Abi::Parser.parse("string")
      expect(type.format).to eq "string"
      base_type = Abi::Parser.parse_base_type("string")
      expect(base_type).to eq ["string", nil, []]

      type = Abi::Parser.parse("uint256[]")
      expect(type.format).to eq "uint256[]"
      base_type = Abi::Parser.parse_base_type("uint256[]")
      expect(base_type).to eq ["uint", 256, [-1]]

      type = Abi::Parser.parse("uint256[][3]")
      expect(type.format).to eq "uint256[][3]"
      base_type = Abi::Parser.parse_base_type("uint256[][3]")
      expect(base_type).to eq ["uint", 256, [-1, 3]]
    end
  end
end
