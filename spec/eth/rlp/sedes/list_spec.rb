# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Rlp::Sedes::List do
  subject(:l1) { Rlp::Sedes::List.new }
  subject(:l2) { Rlp::Sedes::List.new elements: [Rlp::Sedes.big_endian_int, Rlp::Sedes.big_endian_int] }
  subject(:l3) { Rlp::Sedes::List.new elements: [l1, l2, [[[]]]] }

  it "it does not serialize lists of invalid length or type" do
    expect { l1.serialize([[]]) }.to raise_error Error::ListSerializationError, "List has wrong length"
    expect { l1.serialize([5]) }.to raise_error Error::ListSerializationError, "List has wrong length"

    [[], [1, 2, 3], [1, [2, 3], 4]].each do |d|
      expect { l2.serialize(d) }.to raise_error Error::ListSerializationError, "List has wrong length"
    end

    [[], [[], [], [[[]]]], [[], [5, 6], [[]]]].each do |d|
      expect { l3.serialize(d) }.to raise_error Error::ListSerializationError
    end
  end
end
