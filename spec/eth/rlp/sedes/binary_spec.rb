# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Rlp::Sedes::Binary do
  it "does serialize fixed length binary" do
    b = Rlp::Sedes::Binary.fixed_length 3
    expect(b.serialize "foo").to eq "foo"
    expect(b.deserialize "bar").to eq "bar"
    expect { b.serialize "foobar" }.to raise_error Rlp::SerializationError, "Object has invalid length"
    expect { b.deserialize "foobar" }.to raise_error Rlp::DeserializationError, "String has invalid length"
  end
end
