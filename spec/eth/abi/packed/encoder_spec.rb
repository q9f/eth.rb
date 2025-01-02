# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi::Packed::Encoder do
  it "encodes packed types" do
    expect(Util.bin_to_hex Abi.encode_packed(["uint8[]"], [[1, 2, 3]])).to eq "010203"
    expect(Util.bin_to_hex Abi.encode_packed(["uint16[]"], [[1, 2, 3]])).to eq "000100020003"
    expect(Util.bin_to_hex Abi.encode_packed(["uint32"], [17])).to eq "00000011"
    expect(Util.bin_to_hex Abi.encode_packed(["uint64"], [17])).to eq "0000000000000011"
    expect(Util.bin_to_hex Abi.encode_packed(["bool[]"], [[true, false]])).to eq "0100"
    expect(Util.bin_to_hex Abi.encode_packed(["bool"], [true])).to eq "01"
    expect(Util.bin_to_hex Abi.encode_packed(["int32[]"], [[1, 2, 3]])).to eq "000000010000000200000003"
    expect(Util.bin_to_hex Abi.encode_packed(["int64[]"], [[1, 2, 3]])).to eq "000000000000000100000000000000020000000000000003"
    expect(Util.bin_to_hex Abi.encode_packed(["int64"], [17])).to eq "0000000000000011"
    expect(Util.bin_to_hex Abi.encode_packed(["int128"], [17])).to eq "00000000000000000000000000000011"
    expect(Util.bin_to_hex Abi.encode_packed(["bytes1"], ["0x42"])).to eq "42"
    expect(Util.bin_to_hex Abi.encode_packed(["bytes"], ["dave".b])).to eq "64617665"
    expect(Util.bin_to_hex Abi.encode_packed(["string"], ["dave"])).to eq "64617665"
    expect(Util.bin_to_hex Abi.encode_packed(["string"], ["Hello, World"])).to eq "48656c6c6f2c20576f726c64"
    expect(Abi.encode_packed(["address"], ["\xff" * 20])).to eq "\xff" * 20
    expect(Abi.encode_packed(["address"], ["ff" * 20])).to eq "\xff" * 20
    expect(Abi.encode_packed(["address"], ["0x" + "ff" * 20])).to eq "\xff" * 20
    expect(Abi.encode_packed(["address"], [Address.new("0x" + "ff" * 20)])).to eq "\xff" * 20
    expect(Abi.encode_packed(["address"], ["0xA1B28f84a836142b6cB1cf003Ee3B113745268c0"])).to eq "\xA1\xB2\x8F\x84\xA86\x14+l\xB1\xCF\x00>\xE3\xB1\x13tRh\xC0"
    expect(Util.bin_to_hex Abi.encode_packed(["hash32"], ["8<\xAE\xB6pn\x00\xE2\fr\x05XH\x88\xBAW\xBFV\xEA\xFFMDe\xA8<\x9C{\e!GH\xA6"])).to eq "383caeb6706e00e20c7205584888ba57bf56eaff4d4465a83c9c7b1b214748a6"
    expect(Util.bin_to_hex Abi.encode_packed(["hash20"], ["H\x88\xBAW\xBFV\xEA\xFFMDe\xA8<\x9C{\e!GH\xA6"])).to eq "4888ba57bf56eaff4d4465a83c9c7b1b214748a6"
  end

  it "encodes non-standard packed mode (solidity 0.8.28)" do
    #ref https://docs.soliditylang.org/en/v0.8.28/abi-spec.html#non-standard-packed-mode
    # 0xffff42000348656c6c6f2c20776f726c6421
    #   ^^^^                                 int16(-1)
    #       ^^                               bytes1(0x42)
    #         ^^^^                           uint16(0x03)
    #             ^^^^^^^^^^^^^^^^^^^^^^^^^^ string("Hello, world!") without a length field

    expect(Util.bin_to_hex Abi.encode_packed(["int16"], [-1])).to eq "ffff"
    expect(Util.bin_to_hex Abi.encode_packed(["bytes1"], ["0x42"])).to eq "42"
    expect(Util.bin_to_hex Abi.encode_packed(["bytes1"], ["\B"])).to eq "42"
    expect(Util.bin_to_hex Abi.encode_packed(["uint16"], [0x03])).to eq "0003"
    expect(Util.bin_to_hex Abi.encode_packed(["string"], ["Hello, world!"])).to eq "48656c6c6f2c20776f726c6421"
    types = ["int16", "bytes1", "uint16", "string"]
    values = [
      -1, "\B", 0x03, "Hello, world!",
    ]
    expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq "ffff42000348656c6c6f2c20776f726c6421"
  end

  context "wuminzhe's tests" do
    # ref https://github.com/wuminzhe/abi_coder_rb/blob/701af2315cfc94a94872beb6c639ece400fca589/spec/packed_encoding_spec.rb

    it "bool" do
      types = ["bool"]
      values = [true]
      data = "01"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "bytes" do
      types = ["bytes"]
      values = ["dave".b]
      data = "64617665"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "bytes4" do
      types = ["bytes4"]
      values = ["dave"]
      data = "64617665"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "string" do
      types = ["string"]
      values = ["dave"]
      data = "64617665"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "address1" do
      types = ["address"]
      values = ["cd2a3d9f938e13cd947ec05abc7fe734df8dd826"]
      data = "cd2a3d9f938e13cd947ec05abc7fe734df8dd826"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "address2" do
      types = ["address"]
      values = ["cd2a3d9f938e13cd947ec05abc7fe734df8dd826"]
      data = "cd2a3d9f938e13cd947ec05abc7fe734df8dd826"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "address3" do
      types = ["address"]
      values = [0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826]
      data = "cd2a3d9f938e13cd947ec05abc7fe734df8dd826"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "uint32" do
      types = ["uint32"]
      values = [17]
      data = "00000011"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "int64" do
      types = ["int64"]
      values = [17]
      data = "0000000000000011"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    # it "(uint64)" do
    #   types = "[(uint64)]"
    #   values = [[17]]
    #   data = "0000000000000011"

    #   expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    # end

    # it "(int32,uint64)" do
    #   types = ["(int32,uint64)"]
    #   values = [[17, 17]]
    #   data = "000000110000000000000011"

    #   expect do
    #     Abi.encode_packed(type, value)
    #   end.to raise_error("AbiCoderRb::Tuple with multi inner types is not supported in packed mode")
    # end

    it "int32,uint64" do
      types = %w[int32 uint64]
      values = [17, 17]
      data = "000000110000000000000011"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "uint16[]" do
      types = ["uint16[]"]
      values = [[1, 2]]
      data = "00010002"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "bool[]" do
      types = ["bool[]"]
      values = [[true, false]]
      data = "0100"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "uint16[]" do
      types = ["uint16[]"]
      values = [[1, 2]]
      data = "00010002"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "uint16[2]" do
      types = ["uint16[2]"]
      values = [[1, 2]]
      data = "00010002"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "bytes[2]" do
      types = ["bytes[2]"]
      values = [["dave", "dave"]]
      data = "6461766564617665"
      expect(Util.bin_to_hex Abi.encode_packed(types, values)).to eq data
    end

    it "encodes packed types" do
      expect(Util.bin_to_hex Abi.encode_packed(["uint8[]"], [[1, 2, 3]])).to eq "010203"
      expect(Util.bin_to_hex Abi.encode_packed(["uint16[]"], [[1, 2, 3]])).to eq "000100020003"
      expect(Util.bin_to_hex Abi.encode_packed(["uint32"], [17])).to eq "00000011"
      expect(Util.bin_to_hex Abi.encode_packed(["uint64"], [17])).to eq "0000000000000011"
      expect(Util.bin_to_hex Abi.encode_packed(["bool[]"], [[true, false]])).to eq "0100"
      expect(Util.bin_to_hex Abi.encode_packed(["bool"], [true])).to eq "01"
      expect(Util.bin_to_hex Abi.encode_packed(["int32[]"], [[1, 2, 3]])).to eq "000000010000000200000003"
      expect(Util.bin_to_hex Abi.encode_packed(["int64[]"], [[1, 2, 3]])).to eq "000000000000000100000000000000020000000000000003"
      expect(Util.bin_to_hex Abi.encode_packed(["int32"], [17])).to eq "00000011"
      expect(Util.bin_to_hex Abi.encode_packed(["int64"], [17])).to eq "0000000000000011"
      expect(Util.bin_to_hex Abi.encode_packed(["int128"], [17])).to eq "00000000000000000000000000000011"
    end
  end
end
