# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::TupleType do
  it "has a size or not" do
    expect(Abi::TupleType.new([Abi::BytesType.new, Abi::IntType.new(256)]).size).not_to be
    expect(
      Abi::TupleType.new([
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::IntType.new(256)]
        ),
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::IntType.new(256)]
        ),
      ]).size
    ).not_to be
    expect(
      Abi::TupleType.new([
        Abi::ArrayType.new(Abi::IntType.new(256)),
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
      ]).size
    ).not_to be

    expect(
      Abi::TupleType.new([
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
        Abi::FixedArrayType.new(Abi::UIntType.new(256), 2),
      ]).size
    ).to eq 128
    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(8),
        Abi::IntType.new(256),
      ]).size
    ).to eq 64
    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(32),
        Abi::AddressType.new,
        Abi::FixedArrayType.new(Abi::IntType.new(256), 7),
      ]).size
    ).to eq 288
  end

  it "has a format" do
    expect(Abi::TupleType.new([Abi::BytesType.new, Abi::IntType.new(256)]).format).to eq "(bytes,int256)"
    expect(
      Abi::TupleType.new([
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::IntType.new(256)]
        ),
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::UIntType.new(256)]
        ),
      ]).format
    ).to eq "((bytes,int256),(bytes,uint256))"
    expect(
      Abi::TupleType.new([
        Abi::ArrayType.new(Abi::IntType.new(256)),
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
      ]).format
    ).to eq "(int256[],int256[2])"
    expect(
      Abi::TupleType.new([
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
        Abi::FixedArrayType.new(Abi::UIntType.new(256), 4),
      ]).format
    ).to eq "(int256[2],uint256[4])"
    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(8),
        Abi::IntType.new(256),
      ]).format
    ).to eq "(bytes8,int256)"
    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(32),
        Abi::AddressType.new,
        Abi::FixedArrayType.new(Abi::IntType.new(256), 7),
      ]).format
    ).to eq "(bytes32,address,int256[7])"
  end

  it "can be compared" do
    expect(
      Abi::TupleType.new([Abi::BytesType.new, Abi::IntType.new(256)]) == Abi::TupleType.new([Abi::BytesType.new, Abi::IntType.new(256)])
    ).to be_truthy
    expect(
      Abi::TupleType.new([
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::IntType.new(256)]
        ),
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::UIntType.new(256)]
        ),
      ]) == Abi::TupleType.new([
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::IntType.new(256)]
        ),
        Abi::TupleType.new(
          [Abi::BytesType.new, Abi::UIntType.new(256)]
        ),
      ])
    ).to be_truthy
    expect(
      Abi::TupleType.new([
        Abi::ArrayType.new(Abi::IntType.new(256)),
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
      ]) == Abi::TupleType.new([
        Abi::ArrayType.new(Abi::IntType.new(256)),
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
      ])
    ).to be_truthy
    expect(
      Abi::TupleType.new([
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
        Abi::FixedArrayType.new(Abi::UIntType.new(256), 4),
      ]) == Abi::TupleType.new([
        Abi::FixedArrayType.new(Abi::IntType.new(256), 2),
        Abi::FixedArrayType.new(Abi::UIntType.new(256), 4),
      ])
    ).to be_truthy
    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(8),
        Abi::IntType.new(256),
      ]) ==
      Abi::TupleType.new([
        Abi::FixedBytesType.new(8),
        Abi::IntType.new(256),
      ])
    ).to be_truthy
    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(32),
        Abi::AddressType.new,
        Abi::FixedArrayType.new(Abi::IntType.new(256), 7),
      ]) == Abi::TupleType.new([
        Abi::FixedBytesType.new(32),
        Abi::AddressType.new,
        Abi::FixedArrayType.new(Abi::IntType.new(256), 7),
      ])
    ).to be_truthy

    expect(
      Abi::TupleType.new([
        Abi::FixedBytesType.new(8),
        Abi::IntType.new(256),
      ]) == Abi::TupleType.new([
        Abi::FixedBytesType.new(32),
        Abi::AddressType.new,
        Abi::FixedArrayType.new(Abi::IntType.new(256), 7),
      ])
    ).to be_falsy
  end
end
