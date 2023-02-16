# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::ArrayType do
  it "has no size" do
    expect(Abi::ArrayType.new(Abi::BytesType.new).size).not_to be
  end

  it "has a format" do
    expect(Abi::ArrayType.new(Abi::BytesType.new).format).to eq "bytes[]"
    expect(Abi::ArrayType.new(Abi::IntType.new(256)).format).to eq "int256[]"
    expect(Abi::ArrayType.new(Abi::FixedBytesType.new(32)).format).to eq "bytes32[]"
    expect(Abi::ArrayType.new(Abi::AddressType.new).format).to eq "address[]"
  end

  it "can be compared" do
    expect(Abi::ArrayType.new(Abi::BytesType.new) == Abi::ArrayType.new(Abi::BytesType.new)).to be_truthy
    expect(Abi::ArrayType.new(Abi::IntType.new(256)) == Abi::ArrayType.new(Abi::IntType.new(256))).to be_truthy
    expect(Abi::ArrayType.new(Abi::FixedBytesType.new(32)) == Abi::ArrayType.new(Abi::FixedBytesType.new(32))).to be_truthy
    expect(Abi::ArrayType.new(Abi::AddressType.new) == Abi::ArrayType.new(Abi::AddressType.new)).to be_truthy

    expect(Abi::ArrayType.new(Abi::AddressType.new) == Abi::ArrayType.new(Abi::BooleanType.new)).to be_falsy
    expect(Abi::ArrayType.new((Abi::BytesType.new)) == Abi::FixedArrayType.new(Abi::BytesType.new, 2)).to be_falsy
  end
end
