# # -*- encoding : ascii-8bit -*-

require 'spec_helper'

describe Eth::Abi::Constant do
  describe "#SYMBOLS" do
    it "has valid constants" do
      expect(Eth::Abi::BYTE_EMPTY).to eq ""
      expect(Eth::Abi::BYTE_ZERO).to eq "\x00"
      expect(Eth::Abi::BYTE_ONE).to eq "\x01"
      expect(Eth::Abi::TT32).to eq 4294967296
      expect(Eth::Abi::TT256).to eq 115792089237316195423570985008687907853269984665640564039457584007913129639936
      expect(Eth::Abi::UINT_MAX).to eq 115792089237316195423570985008687907853269984665640564039457584007913129639935
      expect(Eth::Abi::UINT_MIN).to eq 0
      expect(Eth::Abi::INT_MAX).to eq 57896044618658097711785492504343953926634992332820282019728792003956564819967
      expect(Eth::Abi::INT_MIN).to eq -57896044618658097711785492504343953926634992332820282019728792003956564819968
      expect(Eth::Abi::HASH_ZERO).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      expect(Eth::Abi::PRIVKEY_ZERO).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      expect(Eth::Abi::PRIVKEY_ZERO_HEX).to eq "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end
end
