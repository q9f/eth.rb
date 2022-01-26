# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Rlp::Sedes::BigEndianInt do
  subject(:integers) {
    [
      256,
      257,
      4839,
      849302,
      483290432,
      483290483290482039482039,
      48930248348219540325894323584235894327865439258743754893066,
    ]
  }
  subject(:negatives) {
    [-1, -100, -255, -256, -2342423]
  }

  it "cannot serialize negative integers" do
    negatives.each do |n|
      expect { Rlp::Sedes.big_endian_int.serialize n }.to raise_error Error::SerializationError, "Cannot serialize negative integers"
    end
  end

  it "can serialize unsigned integers" do
    expect(integers[-1]).to be < 2 ** 256
    integers.each do |u|
      serial = Rlp::Sedes.big_endian_int.serialize u
      deserial = Rlp::Sedes.big_endian_int.deserialize serial
      expect(deserial).to eq u
      expect(serial[0]).not_to eq "\x00" unless u == 0
    end
  end

  it "can serialize single bytes" do
    (1...256).each do |b|
      c = b.chr
      serial = Rlp::Sedes.big_endian_int.serialize b
      expect(serial).to eq c
      deserial = Rlp::Sedes.big_endian_int.deserialize serial
      expect(deserial).to eq b
    end
  end

  it "can (de-)serialize valid data" do
    [
      [256, Util.str_to_bytes("\x01\x00")],
      [1024, Util.str_to_bytes("\x04\x00")],
      [65535, Util.str_to_bytes("\xFF\xFF")],
    ].each do |(n, s)|
      serial = Rlp::Sedes.big_endian_int.serialize n
      deserial = Rlp::Sedes.big_endian_int.deserialize serial
      expect(serial).to eq s
      expect(deserial).to eq n
    end
  end

  it "can (de-)serialize fixed length" do
    s = Rlp::Sedes::BigEndianInt.new 4
    [0, 1, 255, 256, 256 ** 3, 256 ** 4 - 1].each do |i|
      expect(s.serialize(i).length).to eq 4
      expect(s.deserialize(s.serialize i)).to eq i
    end

    [256 ** 4, 256 ** 4 + 1, 256 ** 5, (-1 - 256), "asdf"].each do |i|
      expect { s.serialize(i) }.to raise_error Error::SerializationError
    end

    t = Rlp::Sedes::BigEndianInt.new 2
    expect { t.serialize 256 ** 4 }.to raise_error Error::SerializationError, "Integer too large (does not fit in 2 bytes)"
  end
end
