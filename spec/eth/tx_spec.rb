require "spec_helper"

describe Eth::Tx do
  context "#GAS" do
    it "defines gas limits" do
      expect(Eth::Tx::DEFAULT_LIMIT).to eq 21_000
      expect(Eth::Tx::BLOCK_LIMIT).to eq 25_000_000
    end

    it "defines transaction types" do
      expect(Eth::Tx::TYPE_2930).to eq 1
      expect(Eth::Tx::TYPE_1559).to eq 2
    end
  end

  describe ".santize_list" do
    subject(:list) {
      [
        [
          "de0b295669a9fd93d5f28d9ec85e40f4cb697bae",
          [
            "0000000000000000000000000000000000000000000000000000000000000003",
            "0000000000000000000000000000000000000000000000000000000000000007",
          ],
        ],
        [
          "bb9bc244d798123fde783fcc1c72d3bb8c189413",
          [],
        ],
      ]
    }

    subject(:sane) {
      [
        [
          Eth::Util.hex_to_bin("de0b295669a9fd93d5f28d9ec85e40f4cb697bae"),
          [
            Eth::Util.hex_to_bin("0000000000000000000000000000000000000000000000000000000000000003"),
            Eth::Util.hex_to_bin("0000000000000000000000000000000000000000000000000000000000000007"),
          ],
        ],
        [
          Eth::Util.hex_to_bin("bb9bc244d798123fde783fcc1c72d3bb8c189413"),
          [],
        ],
      ]
    }

    it "can convert access lists from hex to bin" do
      expect(Eth::Tx.sanitize_list list).to eq sane
    end
  end
end
