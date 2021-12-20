# -*- encoding : ascii-8bit -*-

require 'spec_helper'

describe Eth::Abi::Type do
  describe ".initialize" do
    it "can instantiate new types" do
      expect(Eth::Abi::Type.new 'uint', 8, []).to eq Eth::Abi::Type.parse("uint8")
      expect(Eth::Abi::Type.new 'bytes', '32', []).to eq Eth::Abi::Type.parse("bytes32")
      expect(Eth::Abi::Type.new 'uint', 256, [10]).to eq Eth::Abi::Type.parse("uint256[10]")
      expect(Eth::Abi::Type.new 'fixed', '128x128', [1,2,3,0]).to eq Eth::Abi::Type.parse("fixed128x128[1][2][3][]")
    end
  end

  describe ".parse" do
    it "raises parse error for invalid types" do
      expect { Eth::Abi::Type.parse "string8" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "bytes33" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse 'hash'}.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse 'address8' }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse 'bool8' }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse 'decimal' }.to raise_error Eth::Abi::Type::ParseError

      expect { Eth::Abi::Type.parse "int" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "int2" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "int20" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "int512" }.to raise_error Eth::Abi::Type::ParseError

      expect { Eth::Abi::Type.parse "fixed" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "fixed256" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "fixed2x2" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "fixed20x20" }.to raise_error Eth::Abi::Type::ParseError
      expect { Eth::Abi::Type.parse "fixed256x256" }.to raise_error Eth::Abi::Type::ParseError
    end

    it "raises parse error for invalid types" do
      expect(Eth::Abi::Type.size_type).to eq Eth::Abi::Type.parse "uint256"
    end
  end

  describe ".==" do
    it "can compare equal types" do
      expect(Eth::Abi::Type.new('uint', '8', []) == Eth::Abi::Type.parse("uint8")).to be_truthy
      expect(Eth::Abi::Type.new('bytes', 32, []) == Eth::Abi::Type.parse("bytes32")).to be_truthy
      expect(Eth::Abi::Type.new('uint', '256', [10]) == Eth::Abi::Type.parse("uint256[10]")).to be_truthy
      expect(Eth::Abi::Type.new('fixed', '128x128', [1,2,3,0]) == Eth::Abi::Type.parse("fixed128x128[1][2][3][]")).to be_truthy
    end
  end

  describe ".size .nested_sub" do
    it "can compute the type size" do
      expect(Eth::Abi::Type.parse("string").size).to be_nil
      expect(Eth::Abi::Type.parse("bytes").size).to be_nil
      expect(Eth::Abi::Type.parse("uint256[]").size).to be_nil
      expect(Eth::Abi::Type.parse("uint256[4][]").size).to be_nil

      expect(Eth::Abi::Type.parse("bytes32").size).to eq 32
      expect(Eth::Abi::Type.parse("uint256").size).to eq 32
      expect(Eth::Abi::Type.parse("fixed128x128").size).to eq 32
      expect(Eth::Abi::Type.parse("bool").size).to eq 32

      expect(Eth::Abi::Type.parse("uint256[2]").size).to eq 64
      expect(Eth::Abi::Type.parse("address[2][2]").size).to eq 128
      expect(Eth::Abi::Type.parse("ufixed192x64[2][2][2][2][2]").size).to eq 1024
    end

    it "can nest sub types" do
      expect(Eth::Abi::Type.parse("uint256").nested_sub.dimensions).to eq []
      expect(Eth::Abi::Type.parse("uint256[2][]").nested_sub.dimensions).to eq [2]
      expect(Eth::Abi::Type.parse("uint256[2][2]").nested_sub.dimensions).to eq [2]
    end
  end
end
