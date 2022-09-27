# -*- encoding : ascii-8bit -*-

require "spec_helper"

RSpec.describe Eth::Types::Num do
  context "when input is nil" do
    subject { described_class.new }
    it "is expected to create numeric types out of thin air" do
      expect(subject).to be_a(described_class)
      expect(subject).to be_truthy

      expect(subject.hex).to match(Eth::Constant::HEX_REGEX)

      expect(subject.bin.b.ascii_only?).to be_truthy

      expect(subject.dec.to_s).to match(Eth::Constant::DECIMAL_REGEX)

      expect(subject.to_zpadded_hex.size).to eq 64
      expect(subject.to_zpadded_bytes.size).to eq 32
    end
  end

  context "when input is not nil" do
    subject { described_class.new("derp") }

    it "is expected to raise an error" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
