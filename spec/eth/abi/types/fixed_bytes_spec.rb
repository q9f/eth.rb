# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::FixedBytesType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has a size" do
    expect(Abi::FixedBytesType.new(1).size).to eq 32
    expect(Abi::FixedBytesType.new(2).size).to eq 32
    expect(Abi::FixedBytesType.new(8).size).to eq 32
    expect(Abi::FixedBytesType.new(32).size).to eq 32
  end

  it "has a format" do
    expect(Abi::FixedBytesType.new(1).format).to eq "bytes1"
    expect(Abi::FixedBytesType.new(2).format).to eq "bytes2"
    expect(Abi::FixedBytesType.new(8).format).to eq "bytes8"
    expect(Abi::FixedBytesType.new(32).format).to eq "bytes32"
  end

  it "can be compared" do
    expect(Abi::FixedBytesType.new(1) == Abi::FixedBytesType.new(1)).to be_truthy
    expect(Abi::FixedBytesType.new(2) == Abi::FixedBytesType.new(2)).to be_truthy
    expect(Abi::FixedBytesType.new(8) == Abi::FixedBytesType.new(8)).to be_truthy
    expect(Abi::FixedBytesType.new(32) == Abi::FixedBytesType.new(32)).to be_truthy

    expect(Abi::FixedBytesType.new(4) == Abi::FixedBytesType.new(16)).to be_falsy
    expect(Abi::FixedBytesType.new(32) == Abi::BytesType.new).to be_falsy
  end
end
