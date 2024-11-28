# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Rlp do
  describe ".encode .decode" do

    # load official ethereum/tests fixtures for RLPs
    let(:rlp_tests_file) { File.read "spec/fixtures/ethereum/tests/RLPTests/rlptest.json", :encoding => "ascii-8bit" }
    subject(:rlp_tests) { JSON.parse rlp_tests_file }

    it "can encode rlp" do
      rlp_tests.each do |test|
        object = test.last["in"]

        # big integers defined as '#' will be treated as numbers
        object = object.delete("#").to_i if object.is_a? String and object.include? "#"

        # we compare the hex output without prefix in down case
        expected_rlp = Util.remove_hex_prefix test.last["out"].downcase
        encoded = Rlp.encode object
        expect(Util.bin_to_hex encoded).to eq expected_rlp
        expect(encoded).to eq Util.hex_to_bin expected_rlp
      end
    end

    it "can decode rlp" do
      rlp_tests.each do |test|
        expected = test.last["in"]

        # big integers defined as '#' will be treated as numbers
        expected = expected.delete("#").to_i if expected.is_a? String and expected.include? "#"

        # we compare the hex output without prefix in down case
        rlp = Util.remove_hex_prefix test.last["out"].downcase
        decoded = Rlp.decode rlp

        # we have to work with assumptions here, if the input is to be expected
        # a numeric, we also deserialize it for test-convenience
        decoded = Util.deserialize_big_endian_to_int decoded if expected.is_a? Numeric

        # another very specific assumption: for the multilist test case,
        # we need to specifically deserialize the entire list first
        multilist = Rlp::Sedes::List.new elements: [Rlp::Sedes.binary, [Rlp::Sedes.big_endian_int], Rlp::Sedes.big_endian_int]
        decoded = multilist.deserialize decoded if test.first == "multilist"

        expect(decoded).to eq expected
      end
    end

    it "can do both ways, back and forth" do
      rlp_tests.each do |test|
        object = test.last["in"]

        # big integers defined as '#' will be treated as numbers
        object = object.delete("#").to_i if object.is_a? String and object.include? "#"

        # we compare the hex output without prefix in down case
        rlp = Util.remove_hex_prefix test.last["out"].downcase
        encoded = Rlp.encode object
        expect(Util.bin_to_hex encoded).to eq rlp
        expect(encoded).to eq Util.hex_to_bin rlp
        decoded = Rlp.decode encoded

        # we have to work with assumptions here, if the input is to be expected
        # a numeric, we also deserialize it for test-convenience
        decoded = Util.deserialize_big_endian_to_int decoded if object.is_a? Numeric

        # another very specific assumption: for the multilist test case,
        # we need to specifically deserialize the entire list first
        multilist = Rlp::Sedes::List.new elements: [Rlp::Sedes.binary, [Rlp::Sedes.big_endian_int], Rlp::Sedes.big_endian_int]
        decoded = multilist.deserialize decoded if test.first == "multilist"

        expect(decoded).to eq object
        encoded_again = Rlp.encode decoded
        expect(Util.bin_to_hex encoded_again).to eq rlp
        expect(encoded_again).to eq Util.hex_to_bin rlp
      end
    end

    it "properly handles single-byte strings" do
      test_cases = ["a", "b", "1", "\x01"]
      test_cases.each do |input|
        encoded = Eth::Rlp.encode(input)
        decoded = Eth::Rlp.decode(encoded)
        expect(decoded).to eq(input)
      end
    end
  end
end
