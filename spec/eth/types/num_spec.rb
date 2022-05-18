# -*- encoding : ascii-8bit -*-

require "spec_helper"

RSpec.describe Eth::Types::Num do
  context "when input is nil" do
    subject { described_class.new }
    it "is expected to create numeric types out of thin air" do
      expect(subject).to be_a(Num)
      expect(subject).to be_truthy

      expect(subject.to_hex).to be_a(Hex)
      expect(subject.to_hex.to_s).to match(Eth::Constant::HEX_REGEX)

      expect(subject.to_bin).to be_a(Bin)
      expect(subject.to_bin.to_s.b).to have_encoding(Encoding::BINARY)
      expect(subject.to_bin.to_s.b).to_not be_ascii_only

      expect(subject.to_i).to be_a(Dec)
      expect(subject.to_i.to_s).to match(Eth::Constant::DECIMAL_REGEX)

      expect(subject.to_zpadded_hex.size).to eq 64
      expect(subject.to_zpadded_bytes.size).to eq 32
    end
  end
  
  context "when input is not nil" do
    subject { described_class.new('derp') }
    it { is_expected.to raise_error }
  end
end
