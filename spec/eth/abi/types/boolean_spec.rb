# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::BooleanType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has a size" do
    expect(Abi::BooleanType.new.size).to eq 32
  end

  it "has a format" do
    expect(Abi::BooleanType.new.format).to eq "bool"
  end

  it "can be compared" do
    expect(Abi::BooleanType.new == Abi::BooleanType.new).to be_truthy
  end
end
