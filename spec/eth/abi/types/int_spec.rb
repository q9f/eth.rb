# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::IntType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has a size" do
    expect(Abi::IntType.new(8).size).to eq 32
    expect(Abi::IntType.new(16).size).to eq 32
    expect(Abi::IntType.new(64).size).to eq 32
    expect(Abi::IntType.new(256).size).to eq 32
  end

  it "has a format" do
    expect(Abi::IntType.new(8).format).to eq "int8"
    expect(Abi::IntType.new(16).format).to eq "int16"
    expect(Abi::IntType.new(64).format).to eq "int64"
    expect(Abi::IntType.new(256).format).to eq "int256"
  end

  it "can be compared" do
    expect(Abi::IntType.new(8) == Abi::IntType.new(8)).to be_truthy
    expect(Abi::IntType.new(16) == Abi::IntType.new(16)).to be_truthy
    expect(Abi::IntType.new(64) == Abi::IntType.new(64)).to be_truthy
    expect(Abi::IntType.new(256) == Abi::IntType.new(256)).to be_truthy

    expect(Abi::IntType.new(32) == Abi::IntType.new(128)).to be_falsy
    expect(Abi::IntType.new(32) == Abi::UIntType.new).to be_falsy
  end
end
