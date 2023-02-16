# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::UIntType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has a size" do
    expect(Abi::UIntType.new(8).size).to eq 32
    expect(Abi::UIntType.new(16).size).to eq 32
    expect(Abi::UIntType.new(64).size).to eq 32
    expect(Abi::UIntType.new(256).size).to eq 32
  end

  it "has a format" do
    expect(Abi::UIntType.new(8).format).to eq "uint8"
    expect(Abi::UIntType.new(16).format).to eq "uint16"
    expect(Abi::UIntType.new(64).format).to eq "uint64"
    expect(Abi::UIntType.new(256).format).to eq "uint256"
  end

  it "can be compared" do
    expect(Abi::UIntType.new(8) == Abi::UIntType.new(8)).to be_truthy
    expect(Abi::UIntType.new(16) == Abi::UIntType.new(16)).to be_truthy
    expect(Abi::UIntType.new(64) == Abi::UIntType.new(64)).to be_truthy
    expect(Abi::UIntType.new(256) == Abi::UIntType.new(256)).to be_truthy

    expect(Abi::UIntType.new(32) == Abi::UIntType.new(128)).to be_falsy
    expect(Abi::UIntType.new(32) == Abi::IntType.new).to be_falsy
  end
end
