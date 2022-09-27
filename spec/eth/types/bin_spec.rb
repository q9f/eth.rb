# -*- encoding : ascii-8bit -*-

require "spec_helper"

RSpec.describe Eth::Types::Bin do
  include TypeHelper

  context "when input is a byte string" do
    subject { described_class.new(bytes) }

    it "can create numeric types" do
      expects_correct_values_for(subject)
    end
  end

  context "when input is not a byte string" do
    subject { described_class.new("adfafasdfasdfasdf") }

    it "is expected to raise an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
