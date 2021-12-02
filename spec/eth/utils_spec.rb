# -*- encoding : ascii-8bit -*-

require 'spec_helper'


describe Eth::Utils do
  describe ".public_key_to_address" do
  end

  describe ".keccak256" do
    it "hashes keccak256 empty string correctly" do

      # ensures we use the correct version of Keccak256
      # ref https://ethereum.stackexchange.com/a/560
      expected_hash = "\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p"
      keccak_hex = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      actual_hash = Eth::Utils.keccak256('')
      actual_hex = Eth::Utils.bin_to_hex actual_hash
      expect(actual_hash).to eq(expected_hash)
      expect(actual_hex).to eq(keccak_hex)

      # ensures we are not using the final SHA3 FIPS standard
      sha3_hex = "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
      expect(actual_hex).not_to eq(sha3_hex)
    end

    it "hashes oscar barrett's keccak256 string correctly" do

      # ensures we use the correct version of Keccak256
      # ref https://github.com/OscarBarrett/crystal-sha3/blob/7b6f6e02196b106ecf0be01da207dbf1e269009b/README.md
      expected_hash = "q\x9A\xCC\xC6\x1A\x9C\xC1&\x83\x0EY\x06\xF9\xD6r\xD0n\xABo\x85\x97(p\x95\xA2\xC5Z\x8Bw^p\x16"
      keccak_hex = "719accc61a9cc126830e5906f9d672d06eab6f8597287095a2c55a8b775e7016"
      actual_hash = Eth::Utils.keccak256('abc123')
      actual_hex = Eth::Utils.bin_to_hex actual_hash
      expect(actual_hash).to eq(expected_hash)
      expect(actual_hex).to eq(keccak_hex)

      # ensures we are not using the final SHA3 FIPS standard
      sha3_hex = "f58fa3df820114f56e1544354379820cff464c9c41cb3ca0ad0b0843c9bb67ee"
      expect(actual_hex).not_to eq(sha3_hex)
    end
  end

  describe ".bin_to_hex .hex_to_bin .bin_to_prefixed_hex" do
    it "can convert between packed binary strings to hexa-decimal strings" do
      bin = "\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p"
      hex = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      prefixed = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

      # convert back and forth between hexa-decimal and binary strings.
      expect(Eth::Utils.bin_to_hex bin).to eq(hex)
      expect(Eth::Utils.hex_to_bin hex).to eq(bin)
      expect(Eth::Utils.bin_to_prefixed_hex bin).to eq(prefixed)
      expect(Eth::Utils.hex_to_bin prefixed).to eq(bin)
    end

    it "raises an error when given invalid string" do
      expect { Eth::Utils.bin_to_hex 1234 }.to raise_error(TypeError)
      expect { Eth::Utils.hex_to_bin 'xxxx' }.to raise_error(TypeError)
      expect { Eth::Utils.hex_to_bin "\x00\x00" }.to raise_error(TypeError)
      expect { Eth::Utils.hex_to_bin 1234 }.to raise_error(TypeError)
    end
  end

  describe ".prefix_hex .remove_hex_prefix" do
    it "ensures that a hex value has 0x at the beginning" do
      expect(Eth::Utils.prefix_hex('abc')).to eq('0xabc')
      expect(Eth::Utils.prefix_hex('0xabc')).to eq('0xabc')
    end

    it "ensures we can remove 0x hex prefixes" do
      expect(Eth::Utils.remove_hex_prefix('abc')).to eq('abc')
      expect(Eth::Utils.remove_hex_prefix('0xabc')).to eq('abc')
    end

    it "does not reformat the hex or remove leading zeros" do
      expect(Eth::Utils.prefix_hex('0123')).to eq('0x0123')
      expect(Eth::Utils.remove_hex_prefix('0x0123')).to eq('0123')
    end
  end

  describe ".is_hex .is_prefixed" do
    it "can determine prefixed and unprefixed hexa-decimal strings" do

      # Ensure we can detect hexa-decimal strings.
      expect(Eth::Utils.is_hex? "f77a7b601a1902ce8fb866fb304527f6").to be_truthy
      expect(Eth::Utils.is_hex? "B7ktIsrmF4DCxsOVhRmmBMh8ArXRs2I6").to be_falsy

      # Ensure we can detect hexa-decimal prefixes.
      expect(Eth::Utils.is_prefixed? "0x94ead6c8ca752be9383610ee078961").to be_truthy
      expect(Eth::Utils.is_prefixed? "563df9c4690a3be20b5abc9c6705c4c7").to be_falsy

      # Ensure we can add and remove prefixes.
      expect(Eth::Utils.is_prefixed? Eth::Utils.remove_hex_prefix "0xa6cae631a6b7121648cc940613208e").to be_falsy
      expect(Eth::Utils.is_prefixed? Eth::Utils.prefix_hex "fe204081a3959ad1b68a4a671ba5d141").to be_truthy
    end
  end
end
