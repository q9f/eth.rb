# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Eth::Abi do
  describe ".encode .decode" do

    # load official ethereum/tests fixtures for ABIs
    let(:basic_abi_tests_file) { File.read "spec/fixtures/ethereum/tests/ABITests/basic_abi_tests.json" }
    subject(:basic_abi_tests) { JSON.parse basic_abi_tests_file }

    it "can encode abi" do
      basic_abi_tests.each do |test|
        types = test.last["types"]
        args = test.last["args"]
        result = test.last["result"]
        encoded = Eth::Abi.encode types, args
        expect(Eth::Util.bin_to_hex encoded).to eq result
        expect(encoded).to eq Eth::Util.hex_to_bin result
      end

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L46
      bytes = "\x00" * 32 * 3
      expect(Eth::Abi.encode(["address[]"], [["\x00" * 20] * 3])).to eq "#{Eth::Util.zpad_int(32)}#{Eth::Util.zpad_int(3)}#{bytes}"
      expect(Eth::Abi.encode(["uint16[2]"], [[5, 6]])).to eq "#{Eth::Util.zpad_int(5)}#{Eth::Util.zpad_int(6)}"
    end

    it "can decode abi" do
      basic_abi_tests.each do |test|
        types = test.last["types"]
        args = test.last["args"]
        result = test.last["result"]
        decoded = Eth::Abi.decode types, result
        expect(decoded).to eq args
      end
    end

    it "can do both ;)" do
      basic_abi_tests.each do |test|
        types = test.last["types"]
        args = test.last["args"]
        result = test.last["result"]

        encoded = Eth::Abi.encode types, args
        expect(Eth::Util.bin_to_hex encoded).to eq result
        expect(encoded).to eq Eth::Util.hex_to_bin result

        decoded = Eth::Abi.decode types, encoded
        expect(decoded).to eq args

        encoded = Eth::Abi.encode types, decoded
        expect(Eth::Util.bin_to_hex encoded).to eq result
        expect(encoded).to eq Eth::Util.hex_to_bin result

        decoded = Eth::Abi.decode types, result
        expect(decoded).to eq args

        # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L55
        expect(Eth::Abi.decode(["int8"], Eth::Abi.encode(["int8"], [1]))[0]).to eq 1
        expect(Eth::Abi.decode(["int8"], Eth::Abi.encode(["int8"], [-1]))[0]).to eq -1
      end
    end
  end

  subject(:t_bool) { Eth::Abi::Type.parse "bool" }
  subject(:t_uint_8) { Eth::Abi::Type.parse "uint8" }
  subject(:t_int_8) { Eth::Abi::Type.parse "int8" }
  subject(:t_ureal_128_128) { Eth::Abi::Type.parse "ureal128x128" }
  subject(:t_real_128_128) { Eth::Abi::Type.parse "real128x128" }
  subject(:t_bytes) { Eth::Abi::Type.parse "bytes" }
  subject(:t_bytes_8) { Eth::Abi::Type.parse "bytes8" }
  subject(:t_hash_20) { Eth::Abi::Type.parse "hash20" }
  subject(:t_hash_32) { Eth::Abi::Type.parse "hash32" }
  subject(:t_address) { Eth::Abi::Type.parse "address" }

  describe ".encode_type .decode_type" do
    it "can encode types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L60
      expect(Eth::Abi.encode_type t_bool, true).to eq Eth::Util.zpad_int 1
      expect(Eth::Abi.encode_type t_bool, false).to eq Eth::Util.zpad_int 0

      expect(Eth::Abi.encode_type t_uint_8, 255).to eq Eth::Util.zpad_int 255
      expect { Eth::Abi.encode_type t_uint_8, 256 }.to raise_error Eth::Abi::ValueOutOfBounds

      expect(Eth::Abi.encode_type t_int_8, -128).to eq Eth::Util.zpad "\x80", 32
      expect(Eth::Abi.encode_type t_int_8, 127).to eq Eth::Util.zpad "\x7f", 32
      expect { Eth::Abi.encode_type t_int_8, -129 }.to raise_error Eth::Abi::ValueOutOfBounds
      expect { Eth::Abi.encode_type t_int_8, 128 }.to raise_error Eth::Abi::ValueOutOfBounds

      expect(Eth::Abi.encode_type t_ureal_128_128, 0).to eq ("\x00" * 32)
      expect(Eth::Abi.encode_type t_ureal_128_128, 1.125).to eq ("\x00" * 15 + "\x01\x20" + "\x00" * 15)
      expect(Eth::Abi.encode_type t_ureal_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)

      expect(Eth::Abi.encode_type t_real_128_128, -1).to eq ("\xff" * 16 + "\x00" * 16)
      expect(Eth::Abi.encode_type t_real_128_128, -2 ** 127).to eq ("\x80" + "\x00" * 31)
      expect(Eth::Abi.encode_type t_real_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)
      expect(Eth::Abi.encode_type t_real_128_128, 1.125).to eq "#{Eth::Util.zpad_int(1, 16)}\x20#{"\x00" * 15}"
      expect(Eth::Abi.encode_type t_real_128_128, -1.125).to eq "#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}"
      expect { Eth::Abi.encode_type(t_real_128_128, -2 ** 127 - 1) }.to raise_error Eth::Abi::ValueOutOfBounds
      expect { Eth::Abi.encode_type(t_real_128_128, 2 ** 127) }.to raise_error Eth::Abi::ValueOutOfBounds

      expect(Eth::Abi.encode_type t_bytes, "\x01\x02\x03").to eq "#{Eth::Util.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}"

      expect(Eth::Abi.encode_type t_bytes_8, "\x01\x02\x03").to eq "\x01\x02\x03#{"\x00" * 29}"

      expect(Eth::Abi.encode_type t_hash_32, "\xff" * 32).to eq ("\xff" * 32)
      expect(Eth::Abi.encode_type t_hash_32, "ff" * 32).to eq ("\xff" * 32)

      expect(Eth::Abi.encode_type t_address, "\xff" * 20).to eq Eth::Util.zpad("\xff" * 20, 32)
      expect(Eth::Abi.encode_type t_address, "ff" * 20).to eq Eth::Util.zpad("\xff" * 20, 32)
      expect(Eth::Abi.encode_type t_address, "0x" + "ff" * 20).to eq Eth::Util.zpad("\xff" * 20, 32)
    end

    it "can decode types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L105
      expect(Eth::Abi.decode_type(t_address, Eth::Abi.encode_type(t_address, "0x" + "ff" * 20))).to eq "0x" + "ff" * 20

      expect(Eth::Abi.decode_type(t_bytes, Eth::Abi.encode_type(t_bytes, "\x01\x02\x03"))).to eq "\x01\x02\x03"

      expect(Eth::Abi.decode_type(t_bytes_8, Eth::Abi.encode_type(t_bytes_8, "\x01\x02\x03"))).to eq ("\x01\x02\x03" + "\x00" * 5)

      expect(Eth::Abi.decode_type(t_hash_20, Eth::Abi.encode_type(t_hash_20, "ff" * 20))).to eq ("\xff" * 20)

      expect(Eth::Abi.decode_type(t_uint_8, Eth::Abi.encode_type(t_uint_8, 0))).to eq 0
      expect(Eth::Abi.decode_type(t_uint_8, Eth::Abi.encode_type(t_uint_8, 255))).to eq 255

      expect(Eth::Abi.decode_type(t_int_8, Eth::Abi.encode_type(t_int_8, -128))).to eq -128
      expect(Eth::Abi.decode_type(t_int_8, Eth::Abi.encode_type(t_int_8, 127))).to eq 127

      expect(Eth::Abi.decode_type(t_ureal_128_128, Eth::Abi.encode_type(t_ureal_128_128, 0))).to eq 0
      expect(Eth::Abi.decode_type(t_ureal_128_128, Eth::Abi.encode_type(t_ureal_128_128, 125.125))).to eq 125.125
      expect(Eth::Abi.decode_type(t_ureal_128_128, Eth::Abi.encode_type(t_ureal_128_128, 2 ** 128 - 1))).to eq (2 ** 128 - 1).to_f

      expect(Eth::Abi.decode_type(t_real_128_128, Eth::Abi.encode_type(t_real_128_128, 1))).to eq 1
      expect(Eth::Abi.decode_type(t_real_128_128, Eth::Abi.encode_type(t_real_128_128, -1))).to eq -1
      expect(Eth::Abi.decode_type(t_real_128_128, Eth::Abi.encode_type(t_real_128_128, 125.125))).to eq 125.125
      expect(Eth::Abi.decode_type(t_real_128_128, Eth::Abi.encode_type(t_real_128_128, -125.125))).to eq -125.125
      expect(Eth::Abi.decode_type(t_real_128_128, Eth::Abi.encode_type(t_real_128_128, 2 ** 127 - 1))).to eq (2 ** 127 - 1).to_f
      expect(Eth::Abi.decode_type(t_real_128_128, Eth::Abi.encode_type(t_real_128_128, -2 ** 127))).to eq -2 ** 127

      expect(Eth::Abi.decode_type(t_bool, Eth::Abi.encode_type(t_bool, true))).to eq true
      expect(Eth::Abi.decode_type(t_bool, Eth::Abi.encode_type(t_bool, false))).to eq false

      # uncovered edge case
      expect(Eth::Abi.decode_type(Eth::Abi::Type.new("hash", 32, [1]), "8cb9d52661513ac5490483c79ac715f5")).to eq ["8cb9d52661513ac5490483c79ac715f5"]
    end
  end

  describe ".encode_primitive_type .decode_primitive_type" do
    it "can encode primitive types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L60
      expect(Eth::Abi.encode_primitive_type t_bool, true).to eq Eth::Util.zpad_int 1
      expect(Eth::Abi.encode_primitive_type t_bool, false).to eq Eth::Util.zpad_int 0

      expect(Eth::Abi.encode_primitive_type t_uint_8, 255).to eq Eth::Util.zpad_int 255
      expect { Eth::Abi.encode_primitive_type t_uint_8, 256 }.to raise_error Eth::Abi::ValueOutOfBounds

      expect(Eth::Abi.encode_primitive_type t_int_8, -128).to eq Eth::Util.zpad "\x80", 32
      expect(Eth::Abi.encode_primitive_type t_int_8, 127).to eq Eth::Util.zpad "\x7f", 32
      expect { Eth::Abi.encode_primitive_type t_int_8, -129 }.to raise_error Eth::Abi::ValueOutOfBounds
      expect { Eth::Abi.encode_primitive_type t_int_8, 128 }.to raise_error Eth::Abi::ValueOutOfBounds

      expect(Eth::Abi.encode_primitive_type t_ureal_128_128, 0).to eq ("\x00" * 32)
      expect(Eth::Abi.encode_primitive_type t_ureal_128_128, 1.125).to eq ("\x00" * 15 + "\x01\x20" + "\x00" * 15)
      expect(Eth::Abi.encode_primitive_type t_ureal_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)

      expect(Eth::Abi.encode_primitive_type t_real_128_128, -1).to eq ("\xff" * 16 + "\x00" * 16)
      expect(Eth::Abi.encode_primitive_type t_real_128_128, -2 ** 127).to eq ("\x80" + "\x00" * 31)
      expect(Eth::Abi.encode_primitive_type t_real_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)
      expect(Eth::Abi.encode_primitive_type t_real_128_128, 1.125).to eq "#{Eth::Util.zpad_int(1, 16)}\x20#{"\x00" * 15}"
      expect(Eth::Abi.encode_primitive_type t_real_128_128, -1.125).to eq "#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}"
      expect { Eth::Abi.encode_primitive_type(t_real_128_128, -2 ** 127 - 1) }.to raise_error Eth::Abi::ValueOutOfBounds
      expect { Eth::Abi.encode_primitive_type(t_real_128_128, 2 ** 127) }.to raise_error Eth::Abi::ValueOutOfBounds

      expect(Eth::Abi.encode_primitive_type t_bytes, "\x01\x02\x03").to eq "#{Eth::Util.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}"

      expect(Eth::Abi.encode_primitive_type t_bytes_8, "\x01\x02\x03").to eq "\x01\x02\x03#{"\x00" * 29}"

      expect(Eth::Abi.encode_primitive_type t_hash_32, "\xff" * 32).to eq ("\xff" * 32)
      expect(Eth::Abi.encode_primitive_type t_hash_32, "ff" * 32).to eq ("\xff" * 32)

      expect(Eth::Abi.encode_primitive_type t_address, "\xff" * 20).to eq Eth::Util.zpad("\xff" * 20, 32)
      expect(Eth::Abi.encode_primitive_type t_address, "ff" * 20).to eq Eth::Util.zpad("\xff" * 20, 32)
      expect(Eth::Abi.encode_primitive_type t_address, "0x" + "ff" * 20).to eq Eth::Util.zpad("\xff" * 20, 32)

      # uncovered edge cases
      expect(Eth::Abi.encode_primitive_type(t_hash_32, 12354235345634646546346346345)).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'\xEB/\x18\x0E\x84\xD7\xDFU\x8B\ai"
      expect(Eth::Abi.encode_primitive_type(t_address, 98798765498765487654864654687)).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01?<la\xA1\xE3$\xC9\xF6\xCF\x91_"
      expect { Eth::Abi.encode_primitive_type(t_hash_32, "0x8cb9d52661513ac5490483c79ac715f5dd572bfb") }.to raise_error Eth::Abi::EncodingError
      expect { Eth::Abi.encode_primitive_type(t_address, "0x8cb9d52661513ac5490483c79ac715f5dd572bfb0xbd76086b38f2660fcaa65781ff5998f5c18e766d") }.to raise_error Eth::Abi::EncodingError
      expect { Eth::Abi.encode_primitive_type(Eth::Abi::Type.new("foo", 32, []), 12354235345634646546346346345) }.to raise_error Eth::Abi::EncodingError
    end

    it "can decode primitive types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L105
      expect(Eth::Abi.decode_primitive_type(t_address, Eth::Abi.encode_primitive_type(t_address, "0x" + "ff" * 20))).to eq "0x" + "ff" * 20

      expect(Eth::Abi.decode_primitive_type(t_bytes, Eth::Abi.encode_primitive_type(t_bytes, "\x01\x02\x03"))).to eq "\x01\x02\x03"

      expect(Eth::Abi.decode_primitive_type(t_bytes_8, Eth::Abi.encode_primitive_type(t_bytes_8, "\x01\x02\x03"))).to eq ("\x01\x02\x03" + "\x00" * 5)

      expect(Eth::Abi.decode_primitive_type(t_hash_20, Eth::Abi.encode_primitive_type(t_hash_20, "ff" * 20))).to eq ("\xff" * 20)

      expect(Eth::Abi.decode_primitive_type(t_uint_8, Eth::Abi.encode_primitive_type(t_uint_8, 0))).to eq 0
      expect(Eth::Abi.decode_primitive_type(t_uint_8, Eth::Abi.encode_primitive_type(t_uint_8, 255))).to eq 255

      expect(Eth::Abi.decode_primitive_type(t_int_8, Eth::Abi.encode_primitive_type(t_int_8, -128))).to eq -128
      expect(Eth::Abi.decode_primitive_type(t_int_8, Eth::Abi.encode_primitive_type(t_int_8, 127))).to eq 127

      expect(Eth::Abi.decode_primitive_type(t_ureal_128_128, Eth::Abi.encode_primitive_type(t_ureal_128_128, 0))).to eq 0
      expect(Eth::Abi.decode_primitive_type(t_ureal_128_128, Eth::Abi.encode_primitive_type(t_ureal_128_128, 125.125))).to eq 125.125
      expect(Eth::Abi.decode_primitive_type(t_ureal_128_128, Eth::Abi.encode_primitive_type(t_ureal_128_128, 2 ** 128 - 1))).to eq (2 ** 128 - 1).to_f

      expect(Eth::Abi.decode_primitive_type(t_real_128_128, Eth::Abi.encode_primitive_type(t_real_128_128, 1))).to eq 1
      expect(Eth::Abi.decode_primitive_type(t_real_128_128, Eth::Abi.encode_primitive_type(t_real_128_128, -1))).to eq -1
      expect(Eth::Abi.decode_primitive_type(t_real_128_128, Eth::Abi.encode_primitive_type(t_real_128_128, 125.125))).to eq 125.125
      expect(Eth::Abi.decode_primitive_type(t_real_128_128, Eth::Abi.encode_primitive_type(t_real_128_128, -125.125))).to eq -125.125
      expect(Eth::Abi.decode_primitive_type(t_real_128_128, Eth::Abi.encode_primitive_type(t_real_128_128, 2 ** 127 - 1))).to eq (2 ** 127 - 1).to_f
      expect(Eth::Abi.decode_primitive_type(t_real_128_128, Eth::Abi.encode_primitive_type(t_real_128_128, -2 ** 127))).to eq -2 ** 127

      expect(Eth::Abi.decode_primitive_type(t_bool, Eth::Abi.encode_primitive_type(t_bool, true))).to eq true
      expect(Eth::Abi.decode_primitive_type(t_bool, Eth::Abi.encode_primitive_type(t_bool, false))).to eq false

      # uncovered edge-cases
      expect { Eth::Abi.decode_primitive_type(Eth::Abi::Type.new("foo", 32, []), "bar") }.to raise_error Eth::Abi::DecodingError
    end
  end
end
