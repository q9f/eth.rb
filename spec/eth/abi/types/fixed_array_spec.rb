# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::FixedArrayType do
  it "has a size or not" do
    expect(Abi::FixedArrayType.new(Abi::BytesType.new, [2]).size).not_to be

    expect(Abi::FixedArrayType.new(Abi::IntType.new(256), [2]).size).to eq 64
    expect(Abi::FixedArrayType.new(Abi::FixedBytesType.new(32), [16]).size).to eq 512
    expect(Abi::FixedArrayType.new(Abi::AddressType.new, [137]).size).to eq 4384
  end

  it "has a format" do
    expect(Abi::FixedArrayType.new(Abi::BytesType.new, [2]).format).to eq "bytes[2]"
    expect(Abi::FixedArrayType.new(Abi::IntType.new(256), [2]).format).to eq "int256[2]"
    expect(Abi::FixedArrayType.new(Abi::FixedBytesType.new(32), [16]).format).to eq "bytes32[16]"
    expect(Abi::FixedArrayType.new(Abi::AddressType.new, [137]).format).to eq "address[137]"
  end

  it "can be compared" do
    expect(Abi::FixedArrayType.new(Abi::BytesType.new, [2]) == Abi::FixedArrayType.new(Abi::BytesType.new, [2])).to be_truthy
    expect(Abi::FixedArrayType.new(Abi::IntType.new(256), [2]) == Abi::FixedArrayType.new(Abi::IntType.new(256), [2])).to be_truthy
    expect(Abi::FixedArrayType.new(Abi::FixedBytesType.new(32), [16]) == Abi::FixedArrayType.new(Abi::FixedBytesType.new(32), [16])).to be_truthy
    expect(Abi::FixedArrayType.new(Abi::AddressType.new, [137]) == Abi::FixedArrayType.new(Abi::AddressType.new, [137])).to be_truthy

    expect(Abi::FixedArrayType.new(Abi::AddressType.new, [2]) == Abi::FixedArrayType.new(Abi::AddressType.new, [7])).to be_falsy
    expect(Abi::FixedArrayType.new(Abi::AddressType.new, [2]) == Abi::FixedArrayType.new(Abi::BooleanType.new, [2])).to be_falsy
    expect(Abi::FixedArrayType.new(Abi::BytesType.new, [2]) == Abi::ArrayType.new(Abi::BytesType.new)).to be_falsy
  end
end
