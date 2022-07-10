# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi do
  describe ".encode .decode" do

    # load official ethereum/tests fixtures for ABIs
    let(:basic_abi_tests_file) { File.read "spec/fixtures/ethereum/tests/ABITests/basic_abi_tests.json" }
    subject(:basic_abi_tests) { JSON.parse basic_abi_tests_file }

    describe "dynamic encode" do
      it "can encode array of string" do
        encoded = Eth::Util.bin_to_hex(described_class.encode(["string[]"], [["hello", "world"]]))
        expected = "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005776f726c64000000000000000000000000000000000000000000000000000000"
        expect(encoded).to eq(expected)
      end

      it "can encode array of uint256" do
        encoded = Eth::Util.bin_to_hex(described_class.encode(["uint256[]"], [[123, 456]]))
        expected = "00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000007b00000000000000000000000000000000000000000000000000000000000001c8"
        expect(encoded).to eq(expected)
      end

      it "can encode mix of array of uint256 and string" do
        encoded = Eth::Util.bin_to_hex(described_class.encode(["uint256[]", "string[]"], [[123, 456], ["hello", "world"]]))
        expected = "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000007b00000000000000000000000000000000000000000000000000000000000001c8000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005776f726c64000000000000000000000000000000000000000000000000000000"
        expect(encoded).to eq(expected)

        encoded = Eth::Util.bin_to_hex(described_class.encode(["uint256[]", "string[]", "string[]", "uint8[]"], [[123, 456], ["hello", "world"], ["ruby", "ethereum"], [8]]))
        expected = "000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000007b00000000000000000000000000000000000000000000000000000000000001c8000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005776f726c64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000472756279000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008657468657265756d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008"
        expect(encoded).to eq(expected)
      end

      it "can encode array of dynamic structs" do
        encoded = Eth::Util.bin_to_hex(described_class.encode([
          Eth::Abi::Type.parse("tuple[3]", [
            {
              "type" => "tuple",
              "name" => "nuu",
              "components" => [
                "type" => "tuple",
                "name" => "foo",
                "components" => [
                  { "type" => "string", "name" => "id" },
                  { "type" => "string", "name" => "name" },
                ],
              ],
            },
          ]),
          Eth::Abi::Type.parse("tuple[]", [
            {
              "type" => "uint256",
              "name" => "id",
            },
            {
              "type" => "uint256",
              "name" => "data",
            },
          ]),
          Eth::Abi::Type.parse("tuple[]", [
            { "type" => "string", "name" => "id" },
            { "type" => "string", "name" => "name" },
          ]),
          Eth::Abi::Type.parse("tuple[]", [
            {
              "type" => "tuple",
              "name" => "nuu",
              "components" => [
                "type" => "tuple",
                "name" => "foo",
                "components" => [
                  { "type" => "string", "name" => "id" },
                  { "type" => "string", "name" => "name" },
                ],
              ],
            },
          ]),
          Eth::Abi::Type.parse("tuple[3]", [
            { "type" => "string", "name" => "id" },
            { "type" => "string", "name" => "name" },
          ]),
        ], [
          [
            { "nuu" => { "foo" => { "id" => "4", "name" => "nestedFoo" } } },
            { "nuu" => { "foo" => { "id" => "", "name" => "" } } },
            { "nuu" => { "foo" => { "id" => "4", "name" => "nestedFoo" } } },
          ],
          [
            { "id" => 123, "data" => 123 },
            { "id" => 12, "data" => 33 },
            { "id" => 0, "data" => 0 },
          ],
          [
            { "id" => "id", "name" => "name" },
          ],
          [
            { "nuu" => { "foo" => { "id" => "4", "name" => "nestedFoo" } } },
            { "nuu" => { "foo" => { "id" => "4", "name" => "nestedFoo" } } },
            { "nuu" => { "foo" => { "id" => "", "name" => "" } } },
          ],
          [
            { "id" => "id", "name" => "name" },
            { "id" => "id", "name" => "name" },
            { "id" => "id", "name" => "name" },
          ],
        ]))
        expected = "00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000003c000000000000000000000000000000000000000000000000000000000000004a000000000000000000000000000000000000000000000000000000000000005a000000000000000000000000000000000000000000000000000000000000008e000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096e6573746564466f6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096e6573746564466f6f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000007b000000000000000000000000000000000000000000000000000000000000007b000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002696400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046e616d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000026000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096e6573746564466f6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000096e6573746564466f6f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002696400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046e616d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002696400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046e616d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002696400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046e616d6500000000000000000000000000000000000000000000000000000000"
        expect(encoded).to eq(expected)
      end
    end

    it "can encode abi" do
      basic_abi_tests.each do |test|
        types = test.last["types"]
        args = test.last["args"]
        result = test.last["result"]
        encoded = Abi.encode types, args
        expect(Util.bin_to_hex encoded).to eq result
        expect(encoded).to eq Util.hex_to_bin result
      end

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L46
      bytes = "\x00" * 32 * 3
      expect(Abi.encode(["address[]"], [["\x00" * 20] * 3])).to eq "#{Util.zpad_int(32)}#{Util.zpad_int(3)}#{bytes}"
      expect(Abi.encode(["uint16[2]"], [[5, 6]])).to eq "#{Util.zpad_int(5)}#{Util.zpad_int(6)}"
    end

    it "can decode abi" do
      basic_abi_tests.each do |test|
        types = test.last["types"]
        args = test.last["args"]
        result = test.last["result"]
        decoded = Abi.decode types, result
        expect(decoded).to eq args
      end
    end

    it "can do both ways, back and forth" do
      basic_abi_tests.each do |test|
        types = test.last["types"]
        args = test.last["args"]
        result = test.last["result"]

        encoded = Abi.encode types, args
        expect(Util.bin_to_hex encoded).to eq result
        expect(encoded).to eq Util.hex_to_bin result

        decoded = Abi.decode types, encoded
        expect(decoded).to eq args

        encoded = Abi.encode types, decoded
        expect(Util.bin_to_hex encoded).to eq result
        expect(encoded).to eq Util.hex_to_bin result

        decoded = Abi.decode types, result
        expect(decoded).to eq args

        # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L55
        expect(Abi.decode(["int8"], Abi.encode(["int8"], [1]))[0]).to eq 1
        expect(Abi.decode(["int8"], Abi.encode(["int8"], [-1]))[0]).to eq -1
      end
    end

    it "can do encode and decode complex types" do
      types = [
        "bool",
        "string",
        "hash8",
        "hash16",
        "hash32",
        "address",
        "bytes8",
        "bytes16",
        "bytes32",
        "uint8",
        "uint32",
        "uint256",
        "int8",
        "int32",
        "int256",
        "ufixed8x248",
        "ufixed128x128",
        "ufixed224x32",
        "fixed16x240",
        "fixed120x136",
        "fixed192x64",
        "ureal32x224",
        "ureal112x144",
        "ureal216x40",
        "real24x232",
        "real104x152",
        "real184x72",
      ]
      args = [
        true,
        "Lorem, Ipsum!",
        "5ea2f483",
        "f857a5f69ef3b1d6",
        "727aa2fc7c37dae7f8715034a30684e5",
        "0x3ea1e26a2119b038eaf9b27e65cdb401502ae7a4",
        "k\xDE\xCE\xA1[-\xFC\xB6",
        "\b7\x01\xCA\xAA\xD1\x19\x03N\xDD\xE8\xA9\x90\xBD\xAD\xC4",
        "=\x8B\xFB\x13h\xAE\xE2i>\xB3%\xAF\x9F\x81$K\x190K\b{IA\xA1\xE8\x92\xDAP\xBDH\xDF\xE1",
        174,
        3893363474,
        60301460096010527055210599022636314318554451862510786612212422174837688365153,
        -113,
        1601895622,
        -4153010759215853346544872368790226810347211436084119296615430562753409734914,
        63.66398777006226123760574089008052721339184438673538796217134096628685915738,
        177074929705982418363572194112273.8827238551808681127279347507282393998519465,
        98821499299418253575581118390193337030843895142216397267540857889.01747448956,
        27.30074931250845250070758776089747538801742179664476308779818324270386087829,
        -82228826788593438090560643103.5277820203588472468244458211870022854970130269,
        -84123285919081893514125223546444622436439372822803331.1512193120013670384488,
        629856372.6605513722051544588955980424785476894635842015455370355715449804527,
        33411609757213064037378963.77614307961944113929290314212116855493713727600085,
        81920174834144284202135339815838923296212377714320.77878686626123859401392123,
        -4866211.62692133852235672791699382572457989527277715672430590813883295619920,
        -59242022988589225026181.9155783240648197176958994738042609518397368061096803,
        -91319989741702771619440858588015844636341111.5686669249816377141872992204449,
      ]
      encoded = Abi.encode types, args
      decoded = Abi.decode types, encoded
      expect(decoded).to eq args
      expect(Abi.encode types, decoded).to eq encoded

      nested_types = [
        "bool[]",
        "address[]",
        "bytes32[]",
      ]
      nested_args = [
        [
          true,
          false,
        ],
        [
          "0x84ad87d794f867befc597ebae4200b607d0cd9bd",
          "0xb8425e726762a40057a027a0cb7226b9fe6d7e9a",
          "0xcf960c64b6bb464f30aa2e5a245176438b046e58",
        ],
        [
          "\x13\xAE^]b\xD2\xDAD^\x05\b\e\xA8\xD5\x1DK\xBFO\xC7\xDA-ev!\xA1\xABxZ\xA2\x1CE\xEF",
          "\"\x81\x182\xB2\xFC\xC9\e+\xC2.\x19\x83\xAC\xCA\xAC\x05\x18hK\xB5Wf\xBA\x12\xB6\xC8\xA8+Ymp",
          "9\x18\x8C/*\xF7\x9Bpn\x86\b\x05\v\xC2\xA2Q\xD1n\x01w\n\xE6\xA1\xDFo\xBC\xA2.>\x9F\xDD\xE7",
        ],
      ]
      nested_encoded = Abi.encode nested_types, nested_args
      nested_decoded = Abi.decode nested_types, nested_encoded
      expect(nested_decoded).to eq nested_args
      expect(Abi.encode nested_types, nested_decoded).to eq nested_encoded
    end
  end

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

  describe ".encode_type .decode_type" do
    it "can encode types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L60
      expect(Abi.encode_type t_bool, true).to eq Util.zpad_int 1
      expect(Abi.encode_type t_bool, false).to eq Util.zpad_int 0

      expect(Abi.encode_type t_uint_8, 255).to eq Util.zpad_int 255
      expect { Abi.encode_type t_uint_8, 256 }.to raise_error Abi::ValueOutOfBounds

      expect(Abi.encode_type t_int_8, -128).to eq Util.zpad "\x80", 32
      expect(Abi.encode_type t_int_8, 127).to eq Util.zpad "\x7f", 32
      expect { Abi.encode_type t_int_8, -129 }.to raise_error Abi::ValueOutOfBounds
      expect { Abi.encode_type t_int_8, 128 }.to raise_error Abi::ValueOutOfBounds

      expect(Abi.encode_type t_ureal_128_128, 0).to eq ("\x00" * 32)
      expect(Abi.encode_type t_ureal_128_128, 1.125).to eq ("\x00" * 15 + "\x01\x20" + "\x00" * 15)
      expect(Abi.encode_type t_ureal_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)

      expect(Abi.encode_type t_real_128_128, -1).to eq ("\xff" * 16 + "\x00" * 16)
      expect(Abi.encode_type t_real_128_128, -2 ** 127).to eq ("\x80" + "\x00" * 31)
      expect(Abi.encode_type t_real_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)
      expect(Abi.encode_type t_real_128_128, 1.125).to eq "#{Util.zpad_int(1, 16)}\x20#{"\x00" * 15}"
      expect(Abi.encode_type t_real_128_128, -1.125).to eq "#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}"
      expect { Abi.encode_type(t_real_128_128, -2 ** 127 - 1) }.to raise_error Abi::ValueOutOfBounds
      expect { Abi.encode_type(t_real_128_128, 2 ** 127) }.to raise_error Abi::ValueOutOfBounds

      expect(Abi.encode_type t_bytes, "\x01\x02\x03").to eq "#{Util.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}"

      expect(Abi.encode_type t_bytes_8, "\x01\x02\x03").to eq "\x01\x02\x03#{"\x00" * 29}"

      expect(Abi.encode_type t_hash_32, "\xff" * 32).to eq ("\xff" * 32)
      expect(Abi.encode_type t_hash_32, "ff" * 32).to eq ("\xff" * 32)

      expect(Abi.encode_type t_address, "\xff" * 20).to eq Util.zpad("\xff" * 20, 32)
      expect(Abi.encode_type t_address, "ff" * 20).to eq Util.zpad("\xff" * 20, 32)
      expect(Abi.encode_type t_address, "0x" + "ff" * 20).to eq Util.zpad("\xff" * 20, 32)
    end

    it "can handle hex-strings for bytes types" do
      expect(Abi.encode ["bytes4"], ["0x80ac58cd"]).to eq "\x80\xACX\xCD#{"\x00" * 28}"
      expect(Abi.encode ["bytes4"], ["80ac58cd"]).to eq "\x80\xACX\xCD#{"\x00" * 28}"

      # But don't break binary strings
      expect(Abi.encode ["bytes4"], ["\x80\xACX\xCD"]).to eq "\x80\xACX\xCD#{"\x00" * 28}"
      expect(Util.bin_to_hex Abi.encode ["bytes10"], ["1234567890".b]).to eq "3132333435363738393000000000000000000000000000000000000000000000"
    end

    it "can decode types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L105
      expect(Abi.decode_type(t_address, Abi.encode_type(t_address, "0x" + "ff" * 20))).to eq "0x" + "ff" * 20

      expect(Abi.decode_type(t_bytes, Abi.encode_type(t_bytes, "\x01\x02\x03"))).to eq "\x01\x02\x03"

      expect(Abi.decode_type(t_bytes_8, Abi.encode_type(t_bytes_8, "\x01\x02\x03"))).to eq ("\x01\x02\x03" + "\x00" * 5)

      expect(Abi.decode_type(t_hash_20, Abi.encode_type(t_hash_20, "ff" * 20))).to eq ("\xff" * 20)

      expect(Abi.decode_type(t_uint_8, Abi.encode_type(t_uint_8, 0))).to eq 0
      expect(Abi.decode_type(t_uint_8, Abi.encode_type(t_uint_8, 255))).to eq 255

      expect(Abi.decode_type(t_int_8, Abi.encode_type(t_int_8, -128))).to eq -128
      expect(Abi.decode_type(t_int_8, Abi.encode_type(t_int_8, 127))).to eq 127

      expect(Abi.decode_type(t_ureal_128_128, Abi.encode_type(t_ureal_128_128, 0))).to eq 0
      expect(Abi.decode_type(t_ureal_128_128, Abi.encode_type(t_ureal_128_128, 125.125))).to eq 125.125
      expect(Abi.decode_type(t_ureal_128_128, Abi.encode_type(t_ureal_128_128, 2 ** 128 - 1))).to eq (2 ** 128 - 1).to_f

      expect(Abi.decode_type(t_real_128_128, Abi.encode_type(t_real_128_128, 1))).to eq 1
      expect(Abi.decode_type(t_real_128_128, Abi.encode_type(t_real_128_128, -1))).to eq -1
      expect(Abi.decode_type(t_real_128_128, Abi.encode_type(t_real_128_128, 125.125))).to eq 125.125
      expect(Abi.decode_type(t_real_128_128, Abi.encode_type(t_real_128_128, -125.125))).to eq -125.125
      expect(Abi.decode_type(t_real_128_128, Abi.encode_type(t_real_128_128, 2 ** 127 - 1))).to eq (2 ** 127 - 1).to_f
      expect(Abi.decode_type(t_real_128_128, Abi.encode_type(t_real_128_128, -2 ** 127))).to eq -2 ** 127

      expect(Abi.decode_type(t_bool, Abi.encode_type(t_bool, true))).to eq true
      expect(Abi.decode_type(t_bool, Abi.encode_type(t_bool, false))).to eq false

      # uncovered edge case
      expect(Abi.decode_type(Abi::Type.new("hash", 32, [1]), "8cb9d52661513ac5490483c79ac715f5")).to eq ["8cb9d52661513ac5490483c79ac715f5"]
    end
  end

  describe ".encode_primitive_type .decode_primitive_type" do
    it "can encode primitive types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L60
      expect(Abi.encode_primitive_type t_bool, true).to eq Util.zpad_int 1
      expect(Abi.encode_primitive_type t_bool, false).to eq Util.zpad_int 0

      expect(Abi.encode_primitive_type t_uint_8, 255).to eq Util.zpad_int 255
      expect { Abi.encode_primitive_type t_uint_8, 256 }.to raise_error Abi::ValueOutOfBounds

      expect(Abi.encode_primitive_type t_int_8, -128).to eq Util.zpad "\x80", 32
      expect(Abi.encode_primitive_type t_int_8, 127).to eq Util.zpad "\x7f", 32
      expect { Abi.encode_primitive_type t_int_8, -129 }.to raise_error Abi::ValueOutOfBounds
      expect { Abi.encode_primitive_type t_int_8, 128 }.to raise_error Abi::ValueOutOfBounds

      expect(Abi.encode_primitive_type t_ureal_128_128, 0).to eq ("\x00" * 32)
      expect(Abi.encode_primitive_type t_ureal_128_128, 1.125).to eq ("\x00" * 15 + "\x01\x20" + "\x00" * 15)
      expect(Abi.encode_primitive_type t_ureal_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)

      expect(Abi.encode_primitive_type t_real_128_128, -1).to eq ("\xff" * 16 + "\x00" * 16)
      expect(Abi.encode_primitive_type t_real_128_128, -2 ** 127).to eq ("\x80" + "\x00" * 31)
      expect(Abi.encode_primitive_type t_real_128_128, 2 ** 127 - 1).to eq ("\x7f" + "\xff" * 15 + "\x00" * 16)
      expect(Abi.encode_primitive_type t_real_128_128, 1.125).to eq "#{Util.zpad_int(1, 16)}\x20#{"\x00" * 15}"
      expect(Abi.encode_primitive_type t_real_128_128, -1.125).to eq "#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}"
      expect { Abi.encode_primitive_type(t_real_128_128, -2 ** 127 - 1) }.to raise_error Abi::ValueOutOfBounds
      expect { Abi.encode_primitive_type(t_real_128_128, 2 ** 127) }.to raise_error Abi::ValueOutOfBounds

      expect(Abi.encode_primitive_type t_bytes, "\x01\x02\x03").to eq "#{Util.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}"

      expect(Abi.encode_primitive_type t_bytes_8, "\x01\x02\x03").to eq "\x01\x02\x03#{"\x00" * 29}"

      expect(Abi.encode_primitive_type t_hash_32, "\xff" * 32).to eq ("\xff" * 32)
      expect(Abi.encode_primitive_type t_hash_32, "ff" * 32).to eq ("\xff" * 32)

      expect(Abi.encode_primitive_type t_address, "\xff" * 20).to eq Util.zpad("\xff" * 20, 32)
      expect(Abi.encode_primitive_type t_address, "ff" * 20).to eq Util.zpad("\xff" * 20, 32)
      expect(Abi.encode_primitive_type t_address, "0x" + "ff" * 20).to eq Util.zpad("\xff" * 20, 32)

      # uncovered edge cases
      expect(Abi.encode_primitive_type(t_hash_32, 12354235345634646546346346345)).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'\xEB/\x18\x0E\x84\xD7\xDFU\x8B\ai"
      expect(Abi.encode_primitive_type(t_address, 98798765498765487654864654687)).to eq "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01?<la\xA1\xE3$\xC9\xF6\xCF\x91_"
      expect { Abi.encode_primitive_type(t_hash_32, "0x8cb9d52661513ac5490483c79ac715f5dd572bfb") }.to raise_error Abi::EncodingError
      expect { Abi.encode_primitive_type(t_address, "0x8cb9d52661513ac5490483c79ac715f5dd572bfb0xbd76086b38f2660fcaa65781ff5998f5c18e766d") }.to raise_error Abi::EncodingError
      expect { Abi.encode_primitive_type(Abi::Type.new("foo", 32, []), 12354235345634646546346346345) }.to raise_error Abi::EncodingError
    end

    it "can decode primitive types" do

      # https://github.com/cryptape/ruby-ethereum-abi/blob/90d4fa3fc6b568581165eaacdc506b9b9b49e520/test/abi_test.rb#L105
      expect(Abi.decode_primitive_type(t_address, Abi.encode_primitive_type(t_address, "0x" + "ff" * 20))).to eq "0x" + "ff" * 20

      expect(Abi.decode_primitive_type(t_bytes, Abi.encode_primitive_type(t_bytes, "\x01\x02\x03"))).to eq "\x01\x02\x03"

      expect(Abi.decode_primitive_type(t_bytes_8, Abi.encode_primitive_type(t_bytes_8, "\x01\x02\x03"))).to eq ("\x01\x02\x03" + "\x00" * 5)

      expect(Abi.decode_primitive_type(t_hash_20, Abi.encode_primitive_type(t_hash_20, "ff" * 20))).to eq ("\xff" * 20)

      expect(Abi.decode_primitive_type(t_uint_8, Abi.encode_primitive_type(t_uint_8, 0))).to eq 0
      expect(Abi.decode_primitive_type(t_uint_8, Abi.encode_primitive_type(t_uint_8, 255))).to eq 255

      expect(Abi.decode_primitive_type(t_int_8, Abi.encode_primitive_type(t_int_8, -128))).to eq -128
      expect(Abi.decode_primitive_type(t_int_8, Abi.encode_primitive_type(t_int_8, 127))).to eq 127

      expect(Abi.decode_primitive_type(t_ureal_128_128, Abi.encode_primitive_type(t_ureal_128_128, 0))).to eq 0
      expect(Abi.decode_primitive_type(t_ureal_128_128, Abi.encode_primitive_type(t_ureal_128_128, 125.125))).to eq 125.125
      expect(Abi.decode_primitive_type(t_ureal_128_128, Abi.encode_primitive_type(t_ureal_128_128, 2 ** 128 - 1))).to eq (2 ** 128 - 1).to_f

      expect(Abi.decode_primitive_type(t_real_128_128, Abi.encode_primitive_type(t_real_128_128, 1))).to eq 1
      expect(Abi.decode_primitive_type(t_real_128_128, Abi.encode_primitive_type(t_real_128_128, -1))).to eq -1
      expect(Abi.decode_primitive_type(t_real_128_128, Abi.encode_primitive_type(t_real_128_128, 125.125))).to eq 125.125
      expect(Abi.decode_primitive_type(t_real_128_128, Abi.encode_primitive_type(t_real_128_128, -125.125))).to eq -125.125
      expect(Abi.decode_primitive_type(t_real_128_128, Abi.encode_primitive_type(t_real_128_128, 2 ** 127 - 1))).to eq (2 ** 127 - 1).to_f
      expect(Abi.decode_primitive_type(t_real_128_128, Abi.encode_primitive_type(t_real_128_128, -2 ** 127))).to eq -2 ** 127

      expect(Abi.decode_primitive_type(t_bool, Abi.encode_primitive_type(t_bool, true))).to eq true
      expect(Abi.decode_primitive_type(t_bool, Abi.encode_primitive_type(t_bool, false))).to eq false

      # uncovered edge-cases
      expect { Abi.decode_primitive_type(Abi::Type.new("foo", 32, []), "bar") }.to raise_error Abi::DecodingError
    end
  end

  let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
  subject(:erc20_abi) { JSON.parse erc20_abi_file }

  describe ".signature" do
    it "generates Transfer event signature" do
      abi = erc20_abi.find { |i| i["type"] == "event" && i["name"] == "Transfer" }
      signature = Eth::Abi.signature(abi)
      expect(signature).to eq "Transfer(address,address,uint256)"
    end

    it "generates transfer function signature" do
      abi = erc20_abi.find { |i| i["type"] == "function" && i["name"] == "transfer" }
      signature = Eth::Abi.signature(abi)
      expect(signature).to eq "transfer(address,uint256)"
    end
  end
end
