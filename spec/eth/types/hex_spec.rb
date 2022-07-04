# -*- encoding : ascii-8bit -*-

require "spec_helper"

RSpec.describe Eth::Types::Hex do
  include TypeHelpers

  context "when input is nil" do
    subject { described_class.new }
    it { is_expected.to raise_error }
  end

  context "when input is a hex string" do
    context "and input is not 0x-prefixed" do
      subject { described_class.new(hex) }

      it { is_expected.to be_a(Hex) }

      it "is expected to be non-prefixed" do
        expect(subject).to_not start_with?("0x")
      end

      it "can create numeric types" do
        expects_correct_values_for(subject)
      end
    end

    context "and it is prefixed with 0x" do
      subject { described_class.new(prefixed_hex) }

      it { is_expected.to be_a(Hex) }

      it "is expected to be non-prefixed" do
        expect(subject).to_not start_with?("0x")
      end

      it "can create numeric types" do
        expects_correct_values_for(subject)
      end
    end
  end

  context "when input is not nil, but also not a hex string"
    it "should raise an exception" do
      expect { described_class.new('sadkfljas') }.to raise_error(TypeError)
    end
  end
end
