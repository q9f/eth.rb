# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Util do
  describe ".public_key_to_address" do
    it "can create ethereum address from random keys" do
      alice = Util.public_key_to_address Key.new.public_bytes
      expect(alice).to be
      expect(Util.prefixed? alice.to_s).to be_truthy
      expect(alice.checksummed.size).to eq 42

      # same as alice but trying to insert hex
      bob = Util.public_key_to_address Key.new.public_hex
      expect(bob).to be
      expect(Util.prefixed? bob.to_s).to be_truthy
      expect(bob.checksummed.size).to eq 42
    end

    it "turns a hex public key into a hex address" do
      address = "0x8ABC566c5198bc6993526DB697FFe58ce4e2425A"
      public_hex = "0463a1ad6824c03f81ad6c9c224384172c67f6bfd2dbde8c4747a033629b531ae3284db3045e4e40c2b865e22a806ae7dff9264299ea8696321f689d6e134d937e"
      expect(Util.public_key_to_address(public_hex).to_s).to eq address

      public_hex_compressed = "0263a1ad6824c03f81ad6c9c224384172c67f6bfd2dbde8c4747a033629b531ae3"
      expect(Util.public_key_to_address(public_hex_compressed).to_s).to eq address
    end
  end

  describe ".keccak256" do
    it "hashes keccak256 empty string correctly" do

      # ensures we use the correct version of Keccak256
      # ref https://ethereum.stackexchange.com/a/560
      expected_hash = "\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p"
      keccak_hex = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      actual_hash = Util.keccak256 ""
      actual_hex = Util.bin_to_hex actual_hash
      expect(actual_hash).to eq expected_hash
      expect(actual_hex).to eq keccak_hex

      # ensures we are not using the final SHA3 FIPS standard
      sha3_hex = "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
      expect(actual_hex).not_to eq sha3_hex
    end

    it "hashes oscar barrett's keccak256 string correctly" do

      # ensures we use the correct version of Keccak256
      # ref https://github.com/OscarBarrett/crystal-sha3/blob/7b6f6e02196b106ecf0be01da207dbf1e269009b/README.md
      expected_hash = "q\x9A\xCC\xC6\x1A\x9C\xC1&\x83\x0EY\x06\xF9\xD6r\xD0n\xABo\x85\x97(p\x95\xA2\xC5Z\x8Bw^p\x16"
      keccak_hex = "719accc61a9cc126830e5906f9d672d06eab6f8597287095a2c55a8b775e7016"
      actual_hash = Util.keccak256 "abc123"
      actual_hex = Util.bin_to_hex actual_hash
      expect(actual_hash).to eq expected_hash
      expect(actual_hex).to eq keccak_hex

      # ensures we are not using the final SHA3 FIPS standard
      sha3_hex = "f58fa3df820114f56e1544354379820cff464c9c41cb3ca0ad0b0843c9bb67ee"
      expect(actual_hex).not_to eq sha3_hex
    end
  end

  describe ".bin_to_hex .hex_to_bin .bin_to_prefixed_hex" do
    it "can convert between packed binary strings to hexa-decimal strings" do
      bin = "\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p"
      hex = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      prefixed = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"

      # convert back and forth between hexa-decimal and binary strings.
      expect(Util.bin_to_hex bin).to eq hex
      expect(Util.hex_to_bin hex).to eq bin
      expect(Util.bin_to_prefixed_hex bin).to eq prefixed
      expect(Util.hex_to_bin prefixed).to eq bin
    end

    it "raises an error when given invalid string" do
      expect { Util.bin_to_hex 1234 }.to raise_error TypeError
      expect { Util.hex_to_bin "xxxx" }.to raise_error TypeError
      expect { Util.hex_to_bin "\x00\x00" }.to raise_error TypeError
      expect { Util.hex_to_bin 1234 }.to raise_error TypeError
    end

    it "can convert back and forth" do
      expect(Util.bin_to_hex Util.hex_to_bin "a").to eq "0a"
      expect(Util.hex_to_bin Util.bin_to_hex "a").to eq "a"
    end
  end

  describe ".prefix_hex .remove_hex_prefix" do
    it "ensures that a hex value has 0x at the beginning" do
      expect(Util.prefix_hex "abc").to eq "0xabc"
      expect(Util.prefix_hex "0xabc").to eq "0xabc"
    end

    it "ensures we can remove 0x hex prefixes" do
      expect(Util.remove_hex_prefix "abc").to eq "abc"
      expect(Util.remove_hex_prefix "0xabc").to eq "abc"
    end

    it "does not reformat the hex or remove leading zeros" do
      expect(Util.prefix_hex "0123").to eq "0x0123"
      expect(Util.remove_hex_prefix "0x0123").to eq "0123"
    end
  end

  describe ".hex .prefixed" do
    it "can determine prefixed and unprefixed hexa-decimal strings" do

      # Ensure we can detect hexa-decimal strings.
      expect(Util.hex? "f77a7b601a1902ce8fb866fb304527f6").to be_truthy
      expect(Util.hex? "B7ktIsrmF4DCxsOVhRmmBMh8ArXRs2I6").to be_falsy

      # Ensure we can detect hexa-decimal prefixes.
      expect(Util.prefixed? "0x94ead6c8ca752be9383610ee078961").to be_truthy
      expect(Util.prefixed? "563df9c4690a3be20b5abc9c6705c4c7").to be_falsy

      # Ensure we can add and remove prefixes.
      expect(Util.prefixed? Util.remove_hex_prefix "0xa6cae631a6b7121648cc940613208e").to be_falsy
      expect(Util.prefixed? Util.prefix_hex "fe204081a3959ad1b68a4a671ba5d141").to be_truthy
    end
  end

  describe ".serialize_int_to_big_endian .int_to_big_endian" do
    it "can serialize random integers to big endian" do
      expect(Util.serialize_int_to_big_endian 0).to eq ""
      expect(Util.serialize_int_to_big_endian 1).to eq "\x01"
      expect(Util.serialize_int_to_big_endian 16).to eq "\x10"
      expect(Util.serialize_int_to_big_endian 255).to eq "\xFF"
      expect(Util.serialize_int_to_big_endian 256).to eq "\x01\x00"
      expect(Util.serialize_int_to_big_endian 257).to eq "\x01\x01"
      expect(Util.serialize_int_to_big_endian 4839).to eq "\x12\xE7"
      expect(Util.serialize_int_to_big_endian 849302).to eq "\f\xF5\x96"
      expect(Util.serialize_int_to_big_endian 483290432).to eq "\x1C\xCEm@"
      expect(Util.serialize_int_to_big_endian 483290483290482039482039).to eq "fW:\xC6\xD1\xF8\xA8rf\xB7"
      expect(Util.serialize_int_to_big_endian 48930248348219540325894323584235894327865439258743754893066).to eq "\a\xCB\x87\xA1\n\x89\xFE\xAF\xA6\x16@\x92\xC0\xFE\xD6T\x14\x8B\xDC\xF0i7B\xA7\n"
    end

    it "can convert int to big endian" do
      int = [0, 100000, 100000000, 2 ** 256 - 1]
      bytes = ["\x00", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map { |s| s }

      int.zip(bytes).each do |i, b|
        expect(Util.int_to_big_endian i).to eq b
      end
    end

    it "can raises if integers are invalid" do
      negative_ints = [-1, -100, -255, -256, -2342423]
      negative_ints.each do |n|
        expect { Util.serialize_int_to_big_endian n }.to raise_error ArgumentError
      end
    end
  end

  describe ".deserialize_big_endian_to_int .big_endian_to_int" do
    it "can deserialize random integers from big endian string data" do
      expect(Util.deserialize_big_endian_to_int "").to eq 0
      expect(Util.deserialize_big_endian_to_int "\x00").to eq 0
      expect(Util.deserialize_big_endian_to_int "\x00\x00").to eq 0
      expect(Util.deserialize_big_endian_to_int "\x01").to eq 1
      expect(Util.deserialize_big_endian_to_int "\x10").to eq 16
      expect(Util.deserialize_big_endian_to_int "\xFF").to eq 255
      expect(Util.deserialize_big_endian_to_int "\x00\xFF").to eq 255
      expect(Util.deserialize_big_endian_to_int "\x00\x00\xFF").to eq 255
      expect(Util.deserialize_big_endian_to_int "\x01\x00").to eq 256
      expect(Util.deserialize_big_endian_to_int "\x01\x01").to eq 257
      expect(Util.deserialize_big_endian_to_int "\x12\xE7").to eq 4839
      expect(Util.deserialize_big_endian_to_int "\f\xF5\x96").to eq 849302
      expect(Util.deserialize_big_endian_to_int "\x1C\xCEm@").to eq 483290432
      expect(Util.deserialize_big_endian_to_int "fW:\xC6\xD1\xF8\xA8rf\xB7").to eq 483290483290482039482039
      expect(Util.deserialize_big_endian_to_int "\a\xCB\x87\xA1\n\x89\xFE\xAF\xA6\x16@\x92\xC0\xFE\xD6T\x14\x8B\xDC\xF0i7B\xA7\n").to eq 48930248348219540325894323584235894327865439258743754893066
    end

    it "can convert big endian to int" do
      int = [0, 100000, 100000000, 2 ** 256 - 1]
      bytes = ["\x00", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map { |s| s }

      int.zip(bytes).each do |i, b|
        expect(Util.big_endian_to_int b).to eq i
      end
    end
  end

  describe ".ceil32 .lpad .zpad{,_int,_hex}" do
    it "can ceil to the next multiple of 32 bytes" do
      expect(Util.ceil32 0).to eq 0
      expect(Util.ceil32 1).to eq 32
      expect(Util.ceil32 250).to eq 256
      expect(Util.ceil32 256).to eq 256
    end

    it "can left-pad numbers with symbols" do
      expect(Util.lpad "\x00", "\x00", 0).to eq "\x00"
      expect(Util.lpad "\x10", "\x00", 3).to eq "\x00\x00\x10"
      expect(Util.lpad "\x37", "\xff", 10).to eq "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF7"
    end

    it "can left-pad numbers with zeros" do
      expect(Util.zpad "\x00", 0).to eq "\x00"
      expect(Util.zpad "\x10", 3).to eq "\x00\x00\x10"
      expect(Util.zpad "\x37", 10).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x007"
      expect(Util.zpad_hex "00", 0).to eq "\x00"
      expect(Util.zpad_hex "10", 3).to eq "\x00\x00\x10"
      expect(Util.zpad_hex "37", 10).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x007"
      expect(Util.zpad_int 0, 0).to eq ""
      expect(Util.zpad_int 0, 1).to eq "\x00"
      expect(Util.zpad_int 16, 3).to eq "\x00\x00\x10"
      expect(Util.zpad_int 55, 10).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x007"
    end
  end

  describe ".str_to_bytes .bytes_to_str" do
    it "can convert string to bytes" do
      expect(Util.str_to_bytes("abc").encoding.name).to eq "ASCII-8BIT"
    end

    it "can convert bytes to string" do
      expect(Util.bytes_to_str("abc").encoding.name).to eq "UTF-8"
    end
  end

  describe ".bytes? .primitive? .list?" do
    it "can detect RLP types" do
      expect(Util.bytes? Util.str_to_bytes "").to be_truthy
      expect(Util.primitive? "").to be_truthy
      expect(Util.list? []).to be_truthy
    end
  end
end
