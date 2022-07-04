# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Refinements::Conversions do
  class HexDouble
    using Refinements::Conversions

    def initialize(hex = SecureRandom.hex(8))
      @hex = hex
    end

    def hex?
      @hex.hex?
    end

    def hex
      @hex
    end

    def to_hex
      @hex.to_hex
    end

    def to_prefixed_hex
      "0x#{@hex}"
    end

    def odd?
      to_hex.size.odd?
    end
  end

  describe String do
    context 'when hex' do
      context 'when non-prefixed' do
        subject { HexDouble.new }

        describe '#hex?' do
          it { is_expected.to be_hex }
        end

        describe '#to_hex' do
          it { is_expected.to_not start_with('0x') }
          it { is_expected.to_not be_odd }
        end
      end

      context 'when 0x-prefixed' do
        subject { HexDouble.new("0x1111") }

        describe '#hex?' do
          it { is_expected.to be_hex }
        end

        describe '#to_hex' do
          it { is_expected.to_not start_with('0x') }
          it { is_expected.to_not be_odd }
        end
      end
    end
  end
end
