# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Parser do
  it "parses dimensions" do
    expect(Abi::Parser.parse_dimension("uint256")).to eq []
    expect(Abi::Parser.parse_dimension("uint256[]")).to eq [-1]
    expect(Abi::Parser.parse_dimension("uint256[0]")).to eq [0]
    expect(Abi::Parser.parse_dimension("uint256[7]")).to eq [7]
    expect(Abi::Parser.parse_dimension("uint256[1][2][3][]")).to eq [1, 2, 3, -1]
  end

  # it "parses complex types" do
  #   type = Abi::Parser.parse("uint256[3][]")
  #   expect(type.format).to eq "uint256[3][]"
  # end

  context "abicoder tests" do
    it "test_parse_dims" do
      expect(Abi::Parser.parse_dimension("")).to eq []
      expect(Abi::Parser.parse_dimension("[]")).to eq [-1]
      expect(Abi::Parser.parse_dimension("[][3]")).to eq [-1, 3]
      expect(Abi::Parser.parse_dimension("[2][3]")).to eq [2, 3]
    end

    it "test_parse_base_type" do
      expect(Abi::Parser.parse_base_type("uint256")).to eq ["uint", 256, []]
      expect(Abi::Parser.parse_base_type("uint8")).to eq ["uint", 8, []]
      expect(Abi::Parser.parse_base_type("string")).to eq ["string", nil, []]
      expect(Abi::Parser.parse_base_type("uint256[]")).to eq ["uint", 256, [-1]]
      expect(Abi::Parser.parse_base_type("uint256[][3]")).to eq ["uint", 256, [-1, 3]]
      expect(Abi::Parser.parse_base_type("string[]")).to eq ["string", nil, [-1]]
      expect(Abi::Parser.parse_base_type("fixed128x128")).to eq ["fixed", "128x128", []]
    end

    it "test_base" do
      type = Abi::Parser.parse("uint256")
      expect(type.format).to eq "uint256"
      expect(type.class).to eq Eth::Abi::UIntType
      expect(type.bits).to eq 256
      expect(type.dynamic?).to be_falsy
      expect(type.size).to eq 32

      type = Abi::Parser.parse("uint8")
      expect(type.format).to eq "uint8"
      expect(type.class).to eq Eth::Abi::UIntType
      expect(type.bits).to eq 8
      expect(type.dynamic?).to be_falsy
      expect(type.size).to eq 32

      type = Abi::Parser.parse("string")
      expect(type.format).to eq "string"
      expect(type.class).to eq Eth::Abi::StringType
      expect(type.dynamic?).to be_truthy
      expect(type.size).not_to be

      type = Abi::Parser.parse("uint256[]")
      expect(type.format).to eq "uint256[]"
      expect(type.class).to eq Eth::Abi::ArrayType
      expect(type.dynamic?).to be_truthy
      expect(type.size).not_to be

      type = Abi::Parser.parse("string[]")
      expect(type.format).to eq "string[]"
      expect(type.class).to eq Eth::Abi::ArrayType
      expect(type.dynamic?).to be_truthy
      expect(type.size).not_to be
    end

    it "test_parse_tuple_type" do
      expect(Abi::Parser.parse_tuple_type("string,string,bool")).to eq ["string", "string", "bool"]
      expect(Abi::Parser.parse_tuple_type("string,(string,bool)")).to eq ["string", "(string,bool)"]
      expect(Abi::Parser.parse_tuple_type("string,(string,(string,uint256[])),address[4]")).to eq ["string", "(string,(string,uint256[]))", "address[4]"]
    end

    it "test_tuple" do
      type = Abi::Parser.parse("(string,string,bool)")
      expect(type.format).to eq "(string,string,bool)"
      expect(type.class).to eq Eth::Abi::TupleType
      expect(type.dynamic?).to be_truthy
      expect(type.size).not_to be

      type = Abi::Parser.parse("(string,(string,(string,uint256[])),address[4])")
      expect(type.format).to eq "(string,(string,(string,uint256[])),address[4])"
      expect(type.types.map { |t| t.format }).to eq ["string", "(string,(string,uint256[]))", "address[4]"]
      expect(type.class).to eq Eth::Abi::TupleType
      expect(type.dynamic?).to be_truthy
      expect(type.size).not_to be
    end

    it "test_type_parse" do
      expect(Abi::Parser.parse("uint8")).to eq Abi::UIntType.new(8)
      expect(Abi::Parser.parse("bytes32")).to eq Abi::FixedBytesType.new(32)
      expect(Abi::Parser.parse("uint256[10]")).to eq Abi::FixedArrayType.new(Abi::UIntType.new(256), [10])
      # expect(Abi::Parser.parse("fixed128x128[1][2][3][]")).to eq "foo"
    end

    it "test_type_parse_validations" do
      expect {
        Abi::Parser.parse("string8")
      }.to raise_error Abi::ParseError, "String type must have no suffix or numerical suffix"
      expect {
        Abi::Parser.parse("bytes33")
      }.to raise_error Abi::ParseError, "Maximum 32 bytes for fixed-length string or bytes"
      expect {
        Abi::Parser.parse("hash")
      }.to raise_error Abi::ParseError, "Hash type must have numerical suffix"
      expect {
        Abi::Parser.parse("address8")
      }.to raise_error Abi::ParseError, "Address cannot have suffix"
      expect {
        Abi::Parser.parse("bool8")
      }.to raise_error Abi::ParseError, "Bool cannot have suffix"
      expect {
        Abi::Parser.parse("decimal")
      }.to raise_error Abi::ParseError, "Unknown base type: decimal"
      expect {
        Abi::Parser.parse("int")
      }.to raise_error Abi::ParseError, "Integer type must have numerical suffix"
      expect {
        Abi::Parser.parse("int2")
      }.to raise_error Abi::ParseError, "Integer size out of bounds"
      expect {
        Abi::Parser.parse("int20")
      }.to raise_error Abi::ParseError, "Integer size must be multiple of 8"
      expect {
        Abi::Parser.parse("int512")
      }.to raise_error Abi::ParseError, "Integer size out of bounds"
      expect {
        Abi::Parser.parse("fixed")
      }.to raise_error Abi::ParseError, "Real type must have suffix of form <high>x<low>, e.g. 128x128"
      expect {
        Abi::Parser.parse("fixed256")
      }.to raise_error Abi::ParseError, "Real type must have suffix of form <high>x<low>, e.g. 128x128"
      expect {
        Abi::Parser.parse("fixed2x2")
      }.to raise_error Abi::ParseError, "Real size out of bounds (max 32 bytes)"
      expect {
        Abi::Parser.parse("fixed20x20")
      }.to raise_error Abi::ParseError, "Real high/low sizes must be multiples of 8"
      expect {
        Abi::Parser.parse("fixed256x256")
      }.to raise_error Abi::ParseError, "Real size out of bounds (max 32 bytes)"
    end

    it "test_type_size" do
      expect(Abi::Parser.parse("string").size).not_to be
      expect(Abi::Parser.parse("bytes").size).not_to be
      expect(Abi::Parser.parse("uint256[]").size).not_to be
      # expect(Abi::Parser.parse("uint256[4][]").size).not_to be
      expect(Abi::Parser.parse("uint256").size).to eq 32
      expect(Abi::Parser.parse("bool").size).to eq 32
      expect(Abi::Parser.parse("uint256[2]").size).to eq 64
      expect(Abi::Parser.parse("address[2][2]").size).to eq 128
      expect(Abi::Parser.parse("bytes3[2]").size).to eq 64
      # expect(Abi::Parser.parse("fixed128x128").size).to eq 32
      # expect(Abi::Parser.parse("ufixed192x64[2][2][2][2][2]").size).to eq 1024
    end

    it "test_subtype_of_array" do
      type = Abi::Parser.parse("uint256[2][]")
      # expect(type.sub_type.dimension).to eq 2
      # pp type
      # pp type.sub_type
      # pp type.sub_type.sub_type
      # pp type.sub_type.sub_type.sub_type
    end
  end
end
