# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::StringType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has no size" do
    expect(Abi::StringType.new.size).not_to be
  end

  it "has a format" do
    expect(Abi::StringType.new.format).to eq "string"
  end

  it "can be compared" do
    expect(Abi::StringType.new == Abi::StringType.new).to be_truthy
  end
end
