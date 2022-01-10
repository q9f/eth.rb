require "spec_helper"

describe Eth::Tx do
  context "#GAS" do
    it "defines gas limits" do
      expect(Eth::Tx::DEFAULT_GAS_LIMIT).to eq 21_000
      expect(Eth::Tx::DEFAULT_GAS_PRICE).to eq 20_000_000_000
      expect(Eth::Tx::BLOCK_GAS_LIMIT).to eq 25_000_000
    end

    it "defines transaction types" do
      expect(Eth::Tx::TYPE_LEGACY).to eq 0
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

  describe ".decode .unsigned_copy" do
    it "does recognize unknown transaction types" do
      raw = "bf010c80018252088080b8c000000000000000000000000000000000000000000000000000000000000000800000000000000000000000003ea1e26a2119b038eaf9b27e65cdb401502ae7a43d8bfb1368aee2693eb325af9f81244b19304b087b4941a1e892da50bd48dfe1f6d17aad7aff1c87e8481f30395a1595a07b483032affed044e698bf7c43a6fe000000000000000000000000000000000000000000000000000000000000000d4c6f72656d2c20497073756d210000000000000000000000000000000000000026a0e06be7a71c58beebfae09372083865f49fbacb6dfd93f10329f2ca925057fba3a0036c90afd27ea5d2383e319f7091aa23d3e77b09114d7e1d610d04dce8e8169f"
      expect { Eth::Tx.decode raw }.to raise_error Eth::Tx::TransactionTypeError, "Cannot decode unknown transaction type 191!"
    end

    it "can decode transactions with v > 255" do

      # ref https://ethereum.stackexchange.com/questions/38650/field-size-and-value-range-of-chainid-eip-155
      raw = "0xf86e820678850430e2340083015f9094ad322de69695859fc84f32d0f42c3802fe1018438501dcd650008082266ea027caed8171ad1857ff259554614152cda78949adda001e24472f84840bca5cd6a04a5f557baae23ce45c97b71363ea8da6740ac2652bd02b7f94b18cae62d7905a"
      tx = Eth::Tx.decode raw
      expect(tx.sender).to eq Eth::Util.remove_hex_prefix Eth::Address.new("0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1").to_s
      expect(tx.destination).to eq Eth::Util.remove_hex_prefix "0xad322de69695859fc84f32d0f42c3802fe101843"
      expect(tx.amount).to eq 8000000000
      expect(tx.hash).to eq Eth::Util.remove_hex_prefix "0xa0f67799bca1f633f66567455aaeff0728cb72c78d3fff9af0875d4918356c8c"
      expect(tx.signature_v).to eq "266e"
      expect(tx.chain_id).to eq 4901
    end
  end
end
