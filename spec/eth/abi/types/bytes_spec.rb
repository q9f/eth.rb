# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::BytesType do
  it_behaves_like "an ABI type implementing the Meta interface"

  it "has no size" do
    expect(Abi::BytesType.new.size).not_to be
  end

  it "has a format" do
    expect(Abi::BytesType.new.format).to eq "bytes"
  end

  it "can be compared" do
    expect(Abi::BytesType.new == Abi::BytesType.new).to be_truthy
  end
end
