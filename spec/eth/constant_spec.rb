# # -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Eth::Constant do
  describe "#SYMBOLS" do
    it "has valid constants" do
      expect(Constant::BYTE_EMPTY).to eq ""
      expect(Constant::BYTE_ZERO).to eq "\x00"
      expect(Constant::BYTE_ONE).to eq "\x01"
      expect(Constant::TT32).to eq 4294967296
      expect(Constant::TT256).to eq 115792089237316195423570985008687907853269984665640564039457584007913129639936
      expect(Constant::UINT_MAX).to eq 115792089237316195423570985008687907853269984665640564039457584007913129639935
      expect(Constant::UINT_MIN).to eq 0
      expect(Constant::INT_MAX).to eq 57896044618658097711785492504343953926634992332820282019728792003956564819967
      expect(Constant::INT_MIN).to eq -57896044618658097711785492504343953926634992332820282019728792003956564819968
      expect(Constant::HASH_ZERO).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      expect(Constant::SHORT_LENGTH_LIMIT).to eq 56
      expect(Constant::LONG_LENGTH_LIMIT).to eq 18446744073709551616
      expect(Constant::PRIMITIVE_PREFIX_OFFSET).to eq 128
      expect(Constant::LIST_PREFIX_OFFSET).to eq 192
      expect(Constant::INFINITY).to eq 1.0 / 0.0
      expect('0xd00b00').to match Constant::HEX_REGEX
      expect('d00b00').to match Constant::HEX_REGEX
      expect('34103140').to match Constant::DECIMAL_REGEX
    end
  end
end
