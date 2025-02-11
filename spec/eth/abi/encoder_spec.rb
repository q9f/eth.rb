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
end
