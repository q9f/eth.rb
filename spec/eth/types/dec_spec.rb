# -*- encoding : ascii-8bit -*-

require "spec_helper"

RSpec.describe Eth::Types::Dec do
  include TypeHelper

  context "when input is a dec string" do
    subject { described_class.new(integer.to_s) }

    it "can create numeric types" do
      expects_correct_values_for(subject)
    end
  end

  context "when input is an Integer" do
    subject { described_class.new(integer) }

    it "can create numeric types" do
      expects_correct_values_for(subject)
    end
  end

  context "when input is not a dec string or Integer" do
    subject { described_class.new('something') }

    it "is expected to raise an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
