# -*- encoding : ascii-8bit -*-

require 'debug'
require "spec_helper"

describe Eth::Num do
  context "when input is nil" do
    it "is expected to create numeric types out of thin air" do
      10.times do
        num = described_class.new
        expect(num).to be_truthy

        expect(num.to_i).to be_positive
        expect(num.to_zpadded_hex.size).to eq 64
        expect(num.to_zpadded_bytes.size).to eq 32
      end
    end
  end

  context "when input is not nil" do
    def expects_correct_values_for(subject)
      expect(subject.integer).to eq(integer)
      expect(subject.hex).to eq(hex)
      expect(subject.bytes).to eq(bytes)
      expect(subject.to_prefixed_hex).to eq(prefixed_hex)
      expect(subject.to_zpadded_bytes).to eq(zpadded_bytes)
      expect(subject.to_zpadded_hex).to eq(zpadded_hex)
    end

    let(:integer) { 1145256125817859742934257 }
    let(:hex) { "f284757fec556200a4f1" }
    let(:bytes) { "\xF2\x84u\x7F\xECUb\x00\xA4\xF1" }
    let(:prefixed_hex) { "0x#{hex}" }
    let(:zpadded_bytes) { "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xF2\x84u\x7F\xECUb\x00\xA4\xF1" }
    let(:zpadded_hex) { "00000000000000000000000000000000000000000000f284757fec556200a4f1" }

    context "and input is a hex string" do
      context "and it is prefixed with 0x" do
        subject { described_class.new(prefixed_hex) }
        it "can create numeric types" do
          expects_correct_values_for(subject)
        end
      end

      context "and it is not prefixed with 0x" do
        subject { described_class.new(hex) }
        it "can create numeric types" do
          expects_correct_values_for(subject)
        end
      end
    end

    context "when input is an Integer" do
      subject { described_class.new(integer) }
      it "can create numeric types" do
        expects_correct_values_for(subject)
      end
    end

    context "when input is bytes" do
      subject { described_class.new(bytes) }
      it "can create numeric types" do
        expects_correct_values_for(subject)
      end
    end

    it "does not create invalid hex types" do
      expect { described_class.new('sadkfljas') }.to raise_error(TypeError)
    end
  end
end
