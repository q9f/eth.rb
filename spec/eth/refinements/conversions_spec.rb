# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Refinements::Conversions do
  using Refinements::Conversions

  describe 'String' do
    context 'when 0x-prefixed string' do
      describe '#to_hex' do
        it 'removes 0x prefix' do
          
        end
      end
    end
  end
end
