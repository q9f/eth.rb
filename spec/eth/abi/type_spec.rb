# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Type do
  describe ".initialize" do
    it "can instantiate new types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi/type_test.rb#L8
      expect(Abi::Type.new "uint", 8, []).to eq Abi::Type.parse("uint8")
      expect(Abi::Type.new "bytes", "32", []).to eq Abi::Type.parse("bytes32")
      expect(Abi::Type.new "uint", 256, [10]).to eq Abi::Type.parse("uint256[10]")
      expect(Abi::Type.new "fixed", "128x128", [1, 2, 3, 0]).to eq Abi::Type.parse("fixed128x128[1][2][3][]")
      expect(Abi::Type.new "tuple", nil, []).to eq Abi::Type.parse("tuple")
      expect(Abi::Type.new "tuple", nil, [0]).to eq Abi::Type.parse("tuple[]")
      expect(Abi::Type.new "tuple", nil, [10]).to eq Abi::Type.parse("tuple[10]")
    end
  end

  describe ".parse" do
    it "raises parse error for invalid types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi/type_test.rb#L15
      expect { Abi::Type.parse "string8" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "bytes33" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "hash" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "address8" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "bool8" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "decimal" }.to raise_error Abi::Type::ParseError

      expect { Abi::Type.parse "int" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "int2" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "int20" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "int512" }.to raise_error Abi::Type::ParseError

      expect { Abi::Type.parse "fixed" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "fixed256" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "fixed2x2" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "fixed20x20" }.to raise_error Abi::Type::ParseError
      expect { Abi::Type.parse "fixed256x256" }.to raise_error Abi::Type::ParseError
    end

    it "raises parse error for invalid types" do
      expect(Abi::Type.size_type).to eq Abi::Type.parse "uint256"
    end
  end

  describe ".==" do
    it "can compare equal types" do
      expect(Abi::Type.new("uint", "8", []) == Abi::Type.parse("uint8")).to be_truthy
      expect(Abi::Type.new("bytes", 32, []) == Abi::Type.parse("bytes32")).to be_truthy
      expect(Abi::Type.new("uint", "256", [10]) == Abi::Type.parse("uint256[10]")).to be_truthy
      expect(Abi::Type.new("fixed", "128x128", [1, 2, 3, 0]) == Abi::Type.parse("fixed128x128[1][2][3][]")).to be_truthy
    end
  end

  describe ".dynamic?" do
    it "can tell if a type is dynamic" do
      expect(Abi::Type.parse("string").dynamic?).to eq(true)
      expect(Abi::Type.parse("bytes").dynamic?).to eq(true)
      expect(Abi::Type.parse("uint256[]").dynamic?).to eq(true)
      expect(Abi::Type.parse("uint256[4][]").dynamic?).to eq(true)

      expect(Abi::Type.parse("bytes32").dynamic?).to eq(false)
      expect(Abi::Type.parse("uint256").dynamic?).to eq(false)
      expect(Abi::Type.parse("fixed128x128").dynamic?).to eq(false)
      expect(Abi::Type.parse("bool").dynamic?).to eq(false)

      expect(Abi::Type.parse("uint256[2]").dynamic?).to eq(false)
      expect(Abi::Type.parse("address[2][2]").dynamic?).to eq(false)
      expect(Abi::Type.parse("ufixed192x64[2][2][2][2][2]").dynamic?).to eq(false)

      expect(Abi::Type.parse("tuple[]", [{ "type" => "bytes8" }]).dynamic?).to eq(true)
      expect(Abi::Type.parse("tuple[2]", [{ "type" => "bytes8" }]).dynamic?).to eq(false)
    end
  end

  describe ".size .nested_sub" do
    it "can compute the type size" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi/type_test.rb#L35
      expect(Abi::Type.parse("string").size).to be_nil
      expect(Abi::Type.parse("bytes").size).to be_nil
      expect(Abi::Type.parse("uint256[]").size).to be_nil
      expect(Abi::Type.parse("uint256[4][]").size).to be_nil

      expect(Abi::Type.parse("bytes32").size).to eq 32
      expect(Abi::Type.parse("uint256").size).to eq 32
      expect(Abi::Type.parse("fixed128x128").size).to eq 32
      expect(Abi::Type.parse("bool").size).to eq 32

      expect(Abi::Type.parse("uint256[2]").size).to eq 64
      expect(Abi::Type.parse("address[2][2]").size).to eq 128
      expect(Abi::Type.parse("ufixed192x64[2][2][2][2][2]").size).to eq 1024

      expect(Abi::Type.parse("tuple[]", [{ "type" => "uint256" }]).size).to eq(nil)
      expect(Abi::Type.parse("tuple[10]", [{ "type" => "uint256" }]).size).to eq(320)
    end

    it "can nest sub types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi/type_test.rb#L50
      expect(Abi::Type.parse("uint256").nested_sub.dimensions).to eq []
      expect(Abi::Type.parse("uint256[2][]").nested_sub.dimensions).to eq [2]
      expect(Abi::Type.parse("uint256[2][2]").nested_sub.dimensions).to eq [2]
    end
  end

  describe ".to_s" do
    it "serializes type into raw type string" do
      expect(Abi::Type.parse("string").to_s).to eq("string")
      expect(Abi::Type.parse("bytes").to_s).to eq("bytes")
      expect(Abi::Type.parse("bytes32").to_s).to eq("bytes32")
      expect(Abi::Type.parse("string[]").to_s).to eq("string[]")
      expect(Abi::Type.parse("string[10]").to_s).to eq("string[10]")
      expect(Abi::Type.parse("uint256").to_s).to eq("uint256")
      expect(Abi::Type.parse("uint256[2]").to_s).to eq("uint256[2]")
      expect(Abi::Type.parse("uint256[2][]").to_s).to eq("uint256[2][]")
      expect(Abi::Type.parse("uint256[2][2]").to_s).to eq("uint256[2][2]")
      expect(Abi::Type.parse("tuple[]", [
        {
          "type" => "string",
        },
        {
          "type" => "bytes",
        },
      ]).to_s).to eq("(string,bytes)[]")
      expect(Abi::Type.parse("tuple[10]", [
        {
          "type" => "string",
        },
        {
          "type" => "bytes",
        },
      ]).to_s).to eq("(string,bytes)[10]")
      expect(Abi::Type.parse("tuple", [
        {
          "type" => "string",
        },
        {
          "type" => "string",
        },
        {
          "components" => [
            {
              "type" => "uint256",
            },
            {
              "type" => "string",
            },
            {
              "components" => [
                {
                  "type" => "string",
                },
                {
                  "type" => "bytes",
                },
              ],
              "type" => "tuple",
            },
          ],
          "type" => "tuple[]",
        },
        {
          "type" => "uint256",
        },
        {
          "type" => "string[]",
        },
        {
          "type" => "bytes[10]",
        },
        {
          "components" => [
            {
              "type" => "string",
            },
            {
              "type" => "bytes",
            },
          ],
          "type" => "tuple",
        },
      ]).to_s).to eq("(string,string,(uint256,string,(string,bytes))[],uint256,string[],bytes[10],(string,bytes))")
    end
  end
end
