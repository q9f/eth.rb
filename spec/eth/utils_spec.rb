# -*- encoding : ascii-8bit -*-

require 'spec_helper'

describe Eth::Utils do
  it "hashes keccak 256 empty string correctly" do

    # Ensures we use the correct version of Keccak-256
    # ref https://ethereum.stackexchange.com/a/560
    expected_hash = "\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p"
    keccak_hex = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    actual_hash = Eth::Utils.keccak256('')
    actual_hex = Eth::Utils.bin_to_hex actual_hash
    expect(actual_hash).to eq(expected_hash)
    expect(actual_hex).to eq(keccak_hex)

    # Ensure we are not using the final SHA3 FIPS standard
    sha3_hex = "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
    expect(actual_hex).not_to eq(sha3_hex)
  end

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

  it "ensures that a hex value has 0x at the beginning" do
    expect(Eth::Utils.prefix_hex('abc')).to eq('0xabc')
    expect(Eth::Utils.prefix_hex('0xabc')).to eq('0xabc')
  end

  it "does not reformat the hex or remove leading zeros" do
    expect(Eth::Utils.prefix_hex('0123')).to eq('0x0123')
  end

  it "raises an error when given invalid hex" do
    expect {
      Eth::Utils.hex_to_bin('xxxx')
    }.to raise_error(TypeError)

    expect {
      Eth::Utils.hex_to_bin("\x00\x00")
    }.to raise_error(TypeError)
  end

  it "can convert between packed binary strings to hexa-decimal strings" do
    bin = "\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p"
    hex = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    prefixed = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

    # convert back and forth between hexa-decimal and binary strings.
    expect(Eth::Utils.bin_to_hex bin).to eq(hex)
    expect(Eth::Utils.hex_to_bin hex).to eq(bin)
    expect(Eth::Utils.bin_to_prefixed_hex bin).to eq(prefixed)
  end
end
