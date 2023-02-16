# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::AddressType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has a size" do
    expect(Abi::AddressType.new.size).to eq 32
  end

  it "has a format" do
    expect(Abi::AddressType.new.format).to eq "address"
  end

  it "can be compared" do
    expect(Abi::AddressType.new == Abi::AddressType.new).to be_truthy
  end
end
