# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Encoder do
  subject(:t_bool) { Abi::Type.parse "bool" }
  subject(:t_uint_8) { Abi::Type.parse "uint8" }
  subject(:t_int_8) { Abi::Type.parse "int8" }
  subject(:t_ureal_128_128) { Abi::Type.parse "ureal128x128" }
  subject(:t_real_128_128) { Abi::Type.parse "real128x128" }
  subject(:t_bytes) { Abi::Type.parse "bytes" }
  subject(:t_bytes_8) { Abi::Type.parse "bytes8" }
  subject(:t_hash_20) { Abi::Type.parse "hash20" }
  subject(:t_hash_32) { Abi::Type.parse "hash32" }
  subject(:t_address) { Abi::Type.parse "address" }

  it "can encode types" do

    # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L60
    expect(Abi::Encoder.type t_bool, true).to eq Util.zpad_int 1
    expect(Abi::Encoder.type t_bool, false).to eq Util.zpad_int 0

    expect(Abi::Encoder.type t_uint_8, 255).to eq Util.zpad_int 255
    expect { Abi::Encoder.type t_uint_8, 256 }.to raise_error Abi::ValueOutOfBounds

    expect(Abi::Encoder.type t_int_8, -128).to eq Util.zpad "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x80", 32
    expect(Abi::Encoder.type t_int_8, 127).to eq Util.zpad "\x7f", 32
    expect { Abi::Encoder.type t_int_8, -129 }.to raise_error Abi::ValueOutOfBounds
    expect { Abi::Encoder.type t_int_8, 128 }.to raise_error Abi::ValueOutOfBounds

    expect(Abi::Encoder.type t_ureal_128_128, 0).to eq ("\x00" * 32)
    expect(Abi::Encoder.type t_ureal_128_128, 1.125).to eq ("\x00" * 15 + "\x01\x20" + "\x00" * 15)
    expect(Abi::Encoder.type t_ureal_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)

    expect(Abi::Encoder.type t_real_128_128, -1).to eq ("\xff" * 16 + "\x00" * 16)
    expect(Abi::Encoder.type t_real_128_128, -2 ** 127).to eq ("\x80" + "\x00" * 31)
    expect(Abi::Encoder.type t_real_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)
    expect(Abi::Encoder.type t_real_128_128, 1.125).to eq "#{Util.zpad_int(1, 16)}\x20#{"\x00" * 15}"
    expect(Abi::Encoder.type t_real_128_128, -1.125).to eq "#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}"
    expect { Abi::Encoder.type(t_real_128_128, -2 ** 127 - 1) }.to raise_error Abi::ValueOutOfBounds
    expect { Abi::Encoder.type(t_real_128_128, 2 ** 127) }.to raise_error Abi::ValueOutOfBounds

    expect(Abi::Encoder.type t_bytes, "\x01\x02\x03").to eq "#{Util.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}"

    expect(Abi::Encoder.type t_bytes_8, "\x01\x02\x03").to eq "\x01\x02\x03#{"\x00" * 29}"

    expect(Abi::Encoder.type t_hash_32, "\xff" * 32).to eq ("\xff" * 32)
    expect(Abi::Encoder.type t_hash_32, "ff" * 32).to eq ("\xff" * 32)

    expect(Abi::Encoder.type t_address, "\xff" * 20).to eq Util.zpad("\xff" * 20, 32)
    expect(Abi::Encoder.type t_address, "ff" * 20).to eq Util.zpad("\xff" * 20, 32)
    expect(Abi::Encoder.type t_address, "0x" + "ff" * 20).to eq Util.zpad("\xff" * 20, 32)
    expect(Abi::Encoder.type t_address, Address.new("0x" + "ff" * 20)).to eq Util.zpad("\xff" * 20, 32)
  end

  it "can encode primitive types" do

    # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L60
    expect(Abi::Encoder.primitive_type t_bool, true).to eq Util.zpad_int 1
    expect(Abi::Encoder.primitive_type t_bool, false).to eq Util.zpad_int 0

    expect(Abi::Encoder.primitive_type t_uint_8, 255).to eq Util.zpad_int 255
    expect { Abi::Encoder.primitive_type t_uint_8, 256 }.to raise_error Abi::ValueOutOfBounds

    expect(Abi::Encoder.primitive_type t_int_8, -128).to eq Util.zpad "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x80", 32
    expect(Abi::Encoder.primitive_type t_int_8, 127).to eq Util.zpad "\x7f", 32
    expect { Abi::Encoder.primitive_type t_int_8, -129 }.to raise_error Abi::ValueOutOfBounds
    expect { Abi::Encoder.primitive_type t_int_8, 128 }.to raise_error Abi::ValueOutOfBounds

    expect(Abi::Encoder.primitive_type t_ureal_128_128, 0).to eq ("\x00" * 32)
    expect(Abi::Encoder.primitive_type t_ureal_128_128, 1.125).to eq ("\x00" * 15 + "\x01\x20" + "\x00" * 15)
    expect(Abi::Encoder.primitive_type t_ureal_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)

    expect(Abi::Encoder.primitive_type t_real_128_128, -1).to eq ("\xff" * 16 + "\x00" * 16)
    expect(Abi::Encoder.primitive_type t_real_128_128, -2 ** 127).to eq ("\x80" + "\x00" * 31)
    expect(Abi::Encoder.primitive_type t_real_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)
    expect(Abi::Encoder.primitive_type t_real_128_128, 1.125).to eq "#{Util.zpad_int(1, 16)}\x20#{"\x00" * 15}"
    expect(Abi::Encoder.primitive_type t_real_128_128, -1.125).to eq "#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}"
    expect { Abi::Encoder.primitive_type(t_real_128_128, -2 ** 127 - 1) }.to raise_error Abi::ValueOutOfBounds
    expect { Abi::Encoder.primitive_type(t_real_128_128, 2 ** 127) }.to raise_error Abi::ValueOutOfBounds

    expect(Abi::Encoder.primitive_type t_bytes, "\x01\x02\x03").to eq "#{Util.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}"

    expect(Abi::Encoder.primitive_type t_bytes_8, "\x01\x02\x03").to eq "\x01\x02\x03#{"\x00" * 29}"

    expect(Abi::Encoder.primitive_type t_hash_32, "\xff" * 32).to eq ("\xff" * 32)
    expect(Abi::Encoder.primitive_type t_hash_32, "ff" * 32).to eq ("\xff" * 32)

    expect(Abi::Encoder.primitive_type t_address, "\xff" * 20).to eq Util.zpad("\xff" * 20, 32)
    expect(Abi::Encoder.primitive_type t_address, "ff" * 20).to eq Util.zpad("\xff" * 20, 32)
    expect(Abi::Encoder.primitive_type t_address, "0x" + "ff" * 20).to eq Util.zpad("\xff" * 20, 32)

    # uncovered edge cases
    expect(Abi::Encoder.primitive_type(t_hash_32, 12354235345634646546346346345)).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'\xEB/\x18\x0E\x84\xD7\xDFU\x8B\ai"
    expect(Abi::Encoder.primitive_type(t_address, 98798765498765487654864654687)).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01?<la\xA1\xE3$\xC9\xF6\xCF\x91_"
    expect { Abi::Encoder.primitive_type(t_hash_32, "0x8cb9d52661513ac5490483c79ac715f5dd572bfb") }.to raise_error Abi::EncodingError
    expect { Abi::Encoder.primitive_type(t_address, "0x8cb9d52661513ac5490483c79ac715f5dd572bfb0xbd76086b38f2660fcaa65781ff5998f5c18e766d") }.to raise_error Abi::EncodingError
    expect { Abi::Encoder.primitive_type(Abi::Type.new("foo", 32, []), 12354235345634646546346346345) }.to raise_error Abi::EncodingError
  end

  describe "#tuple" do
    it "rejects non-collection arguments" do
      type = Abi::Type.parse("(uint256)", [{ "type" => "uint256" }])
      expect { Abi::Encoder.send(:tuple, "foo", type) }.to raise_error Abi::EncodingError, /Expecting Hash or Array/
    end
  end

  describe "tuple arrays" do
    let(:tuple_components) do
      [
        { "name" => "count", "type" => "uint256" },
        { "name" => "label", "type" => "string" },
      ]
    end

    let(:tuple_type) { Abi::Type.parse("(uint256,string)", tuple_components) }
    let(:dynamic_array_type) { Abi::Type.parse("(uint256,string)[]", tuple_components) }
    let(:static_array_type) { Abi::Type.parse("(uint256,string)[2]", tuple_components) }

    it "encodes dynamic arrays of tuples with dynamic members" do
      values = [[1, "alpha"], [2, "bravo"]]
      encoded = Abi::Encoder.type(dynamic_array_type, values)

      expect(encoded[0, 32]).to eq Abi::Encoder.type(Abi::Type.size_type, values.length)
      first_offset = Util.deserialize_big_endian_to_int encoded[32, 32]
      expect(first_offset).to eq values.length * 32
      expect(Abi::Decoder.type(dynamic_array_type, encoded)).to eq values
    end

    it "encodes static arrays of tuples with dynamic members" do
      values = [[3, "charlie"], [4, "delta"]]
      encoded = Abi::Encoder.type(static_array_type, values)

      first_offset = Util.deserialize_big_endian_to_int encoded[0, 32]
      expect(first_offset).to eq values.length * 32

      second_offset = Util.deserialize_big_endian_to_int encoded[32, 32]
      expect(second_offset).to eq values.length * 32 + Abi::Encoder.type(tuple_type, values[0]).size

      expect(Abi::Decoder.type(static_array_type, encoded)).to eq values
    end

    it "encodes nested arrays of tuples" do
      nested_type = Abi::Type.parse("(uint256,string)[][2]", tuple_components)
      values = [
        [[5, "echo"]],
        [[6, "foxtrot"], [7, "golf"]],
      ]

      encoded = Abi::Encoder.type(nested_type, values)
      expect(Abi::Decoder.type(nested_type, encoded)).to eq values
    end

    it "rejects incorrect cardinality" do
      expect do
        Abi::Encoder.send(:encode_array, static_array_type, [[1, "a"]])
      end.to raise_error Abi::EncodingError, /Expecting 2 elements/
    end
  end

  describe "static tuple arrays" do
    let(:tuple_components) do
      [
        { "type" => "uint256" },
        { "type" => "uint32" },
      ]
    end
    let(:static_tuple_array) { Abi::Type.parse("(uint256,uint32)[2]", tuple_components) }

    it "encodes static arrays with static tuple members" do
      values = [[10, 1], [11, 2]]
      encoded = Abi::Encoder.type(static_tuple_array, values)
      expect(encoded.size).to eq static_tuple_array.size
      expect(Abi::Decoder.type(static_tuple_array, encoded)).to eq values
    end
  end

  describe "#coerce_number" do
    it "coerces numeric strings" do
      expect(Abi::Encoder.send(:coerce_number, "0xff")).to eq 255
      expect(Abi::Encoder.send(:coerce_number, "-42")).to eq(-42)
      expect(Abi::Encoder.send(:coerce_number, 7)).to eq 7
    end

    it "coerces decimal strings" do
      expect(Abi::Encoder.send(:coerce_number, "1.5")).to eq BigDecimal("1.5")
    end

    it "returns original value for other strings" do
      expect(Abi::Encoder.send(:coerce_number, "foo")).to eq "foo"
    end
  end

  describe "binary bytesN starting with 0x or 0X" do
    # About 1 in 32,768 random values start with the bytes of "0x" or "0X".
    subject(:digest_0x) { Util.keccak256 "122654" }
    subject(:digest_0X) { Util.keccak256 "171208" }
    subject(:t_bytes_32) { Abi::Type.parse "bytes32" }

    it "encodes N binary bytes as themselves" do
      expect(Util.bin_to_hex digest_0x).to start_with "3078"
      expect(Util.bin_to_hex digest_0X).to start_with "3058"
      expect(Abi::Encoder.type t_bytes_32, digest_0x).to eq digest_0x
      expect(Abi::Encoder.type t_bytes_32, digest_0X).to eq digest_0X
      expect(Abi::Encoder.type Abi::Type.parse("bytes32[]"), [digest_0x]).to eq "#{Util.zpad_int 1}#{digest_0x}"
      expect(Abi.encode ["bytes32", "uint8"], [digest_0X, 1]).to eq "#{digest_0X}#{Util.zpad_int 1}"

      # https://github.com/q9f/eth.rb/issues/417 (case 1)
      binary = ["3078" + "ab" * 30].pack("H*")
      expect(Abi.encode ["bytes32"], [binary]).to eq binary
    end

    it "encodes N bytes of 0x and hex digits as binary, not as a shorter hex value" do
      # https://github.com/q9f/eth.rb/issues/417 (case 2)
      expect(Abi::Encoder.type t_bytes_32, "0x" + "a" * 30).to eq "0x" + "a" * 30
      expect(Abi::Encoder.type Abi::Type.parse("bytes4"), "0xab").to eq "0xab#{"\x00" * 28}"
      expect(Abi::Encoder.type Abi::Type.parse("bytes2"), "0x").to eq "0x#{"\x00" * 30}"
    end

    it "keeps reading hex of the other lengths as hex" do
      hex = Util.bin_to_hex digest_0x
      expect(Abi::Encoder.type t_bytes_32, "0x#{hex}").to eq digest_0x
      expect(Abi::Encoder.type t_bytes_32, "0X#{hex}").to eq digest_0x
      expect(Abi::Encoder.type t_bytes_32, hex).to eq digest_0x
      expect(Abi::Encoder.type t_bytes_8, "0x0102").to eq "\x01\x02#{"\x00" * 30}"
    end

    it "encodes the official examples with exactly N bytes" do
      # https://docs.soliditylang.org/en/v0.8.28/abi-spec.html, section "Examples":
      # bar(bytes3[2]) with ["abc", "def"]
      encoded = Abi::Encoder.type Abi::Type.parse("bytes3[2]"), ["abc", "def"]
      expect(Util.bin_to_hex encoded).to eq "6162630000000000000000000000000000000000000000000000000000000000" \
                                            "6465660000000000000000000000000000000000000000000000000000000000"

      # Same page, section "Use of Dynamic Types", and GithubWikiTest in
      # ethereum/tests ABITests/basic_abi_tests.json (submodule at a0e84826)
      types = ["uint256", "uint32[]", "bytes10", "bytes"]
      args = [0x123, [0x456, 0x789], "1234567890", "Hello, world!"]
      expect(Util.bin_to_hex Abi.encode(types, args)).to eq "00000000000000000000000000000000000000000000000000000000000001230000000000000000000000000000000000000000000000000000000000000080313233343536373839300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000004560000000000000000000000000000000000000000000000000000000000000789000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000"
    end
  end
end
