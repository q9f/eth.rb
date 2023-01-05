# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Decoder do
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

  it "can decode types" do

    # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L105
    expect(Abi::Decoder.type(t_address, Abi::Encoder.type(t_address, "0x" + "ff" * 20))).to eq "0x" + "ff" * 20

    expect(Abi::Decoder.type(t_bytes, Abi::Encoder.type(t_bytes, "\x01\x02\x03"))).to eq "\x01\x02\x03"

    expect(Abi::Decoder.type(t_bytes_8, Abi::Encoder.type(t_bytes_8, "\x01\x02\x03"))).to eq ("\x01\x02\x03" + "\x00" * 5)

    expect(Abi::Decoder.type(t_hash_20, Abi::Encoder.type(t_hash_20, "ff" * 20))).to eq ("\xff" * 20)

    expect(Abi::Decoder.type(t_uint_8, Abi::Encoder.type(t_uint_8, 0))).to eq 0
    expect(Abi::Decoder.type(t_uint_8, Abi::Encoder.type(t_uint_8, 255))).to eq 255

    expect(Abi::Decoder.type(t_int_8, Abi::Encoder.type(t_int_8, -128))).to eq -128
    expect(Abi::Decoder.type(t_int_8, Abi::Encoder.type(t_int_8, 127))).to eq 127

    expect(Abi::Decoder.type(t_ureal_128_128, Abi::Encoder.type(t_ureal_128_128, 0))).to eq 0
    expect(Abi::Decoder.type(t_ureal_128_128, Abi::Encoder.type(t_ureal_128_128, 125.125))).to eq 125.125
    expect(Abi::Decoder.type(t_ureal_128_128, Abi::Encoder.type(t_ureal_128_128, 2 ** 128 - 1))).to eq (2 ** 128 - 1).to_f

    expect(Abi::Decoder.type(t_real_128_128, Abi::Encoder.type(t_real_128_128, 1))).to eq 1
    expect(Abi::Decoder.type(t_real_128_128, Abi::Encoder.type(t_real_128_128, -1))).to eq -1
    expect(Abi::Decoder.type(t_real_128_128, Abi::Encoder.type(t_real_128_128, 125.125))).to eq 125.125
    expect(Abi::Decoder.type(t_real_128_128, Abi::Encoder.type(t_real_128_128, -125.125))).to eq -125.125
    expect(Abi::Decoder.type(t_real_128_128, Abi::Encoder.type(t_real_128_128, 2 ** 127 - 1))).to eq (2 ** 127 - 1).to_f
    expect(Abi::Decoder.type(t_real_128_128, Abi::Encoder.type(t_real_128_128, -2 ** 127))).to eq -2 ** 127

    expect(Abi::Decoder.type(t_bool, Abi::Encoder.type(t_bool, true))).to eq true
    expect(Abi::Decoder.type(t_bool, Abi::Encoder.type(t_bool, false))).to eq false

    # uncovered edge case
    expect(Abi::Decoder.type(Abi::Type.new("hash", 32, [1]), "8cb9d52661513ac5490483c79ac715f5")).to eq ["8cb9d52661513ac5490483c79ac715f5"]
  end

  it "can decode primitive types" do

    # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L105
    expect(Abi::Decoder.primitive_type(t_address, Abi::Encoder.primitive_type(t_address, "0x" + "ff" * 20))).to eq "0x" + "ff" * 20

    expect(Abi::Decoder.primitive_type(t_bytes, Abi::Encoder.primitive_type(t_bytes, "\x01\x02\x03"))).to eq "\x01\x02\x03"

    expect(Abi::Decoder.primitive_type(t_bytes_8, Abi::Encoder.primitive_type(t_bytes_8, "\x01\x02\x03"))).to eq ("\x01\x02\x03" + "\x00" * 5)

    expect(Abi::Decoder.primitive_type(t_hash_20, Abi::Encoder.primitive_type(t_hash_20, "ff" * 20))).to eq ("\xff" * 20)

    expect(Abi::Decoder.primitive_type(t_uint_8, Abi::Encoder.primitive_type(t_uint_8, 0))).to eq 0
    expect(Abi::Decoder.primitive_type(t_uint_8, Abi::Encoder.primitive_type(t_uint_8, 255))).to eq 255

    expect(Abi::Decoder.primitive_type(t_int_8, Abi::Encoder.primitive_type(t_int_8, -128))).to eq -128
    expect(Abi::Decoder.primitive_type(t_int_8, Abi::Encoder.primitive_type(t_int_8, 127))).to eq 127

    expect(Abi::Decoder.primitive_type(t_ureal_128_128, Abi::Encoder.primitive_type(t_ureal_128_128, 0))).to eq 0
    expect(Abi::Decoder.primitive_type(t_ureal_128_128, Abi::Encoder.primitive_type(t_ureal_128_128, 125.125))).to eq 125.125
    expect(Abi::Decoder.primitive_type(t_ureal_128_128, Abi::Encoder.primitive_type(t_ureal_128_128, 2 ** 128 - 1))).to eq (2 ** 128 - 1).to_f

    expect(Abi::Decoder.primitive_type(t_real_128_128, Abi::Encoder.primitive_type(t_real_128_128, 1))).to eq 1
    expect(Abi::Decoder.primitive_type(t_real_128_128, Abi::Encoder.primitive_type(t_real_128_128, -1))).to eq -1
    expect(Abi::Decoder.primitive_type(t_real_128_128, Abi::Encoder.primitive_type(t_real_128_128, 125.125))).to eq 125.125
    expect(Abi::Decoder.primitive_type(t_real_128_128, Abi::Encoder.primitive_type(t_real_128_128, -125.125))).to eq -125.125
    expect(Abi::Decoder.primitive_type(t_real_128_128, Abi::Encoder.primitive_type(t_real_128_128, 2 ** 127 - 1))).to eq (2 ** 127 - 1).to_f
    expect(Abi::Decoder.primitive_type(t_real_128_128, Abi::Encoder.primitive_type(t_real_128_128, -2 ** 127))).to eq -2 ** 127

    expect(Abi::Decoder.primitive_type(t_bool, Abi::Encoder.primitive_type(t_bool, true))).to eq true
    expect(Abi::Decoder.primitive_type(t_bool, Abi::Encoder.primitive_type(t_bool, false))).to eq false

    # uncovered edge-cases
    expect { Abi::Decoder.primitive_type(Abi::Type.new("foo", 32, []), "bar") }.to raise_error Abi::DecodingError
  end
end
