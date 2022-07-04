# -*- encoding : ascii-8bit -*-

require "spec_helper"

RSpec.describe Eth::Types::Bin do
  include TypeHelpers

  context "when input is nil" do
    subject { described_class.new }
    it { is_expected.to raise_error }
  end

  context "when input is a byte string" do
    subject { described_class.new(bin) }

    it "can create numeric types" do
      expects_correct_values_for(subject)
    end
  end

  context "when input is not a byte string" do
    subject { described_class.new('adfafasdfasdfasdf') }
    it { is_expected.to raise_error }
  end
end
