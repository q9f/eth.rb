# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Tx::Eip4844 do
  subject(:blob_hashes) { ["0x" + "11" * 32] }

  subject(:tx) do
    Tx.new({
      nonce: 0,
      priority_fee: 0,
      max_gas_fee: Unit::WEI,
      gas_limit: Tx::DEFAULT_GAS_LIMIT,
      to: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
      max_fee_per_blob_gas: Unit::WEI,
      blob_versioned_hashes: blob_hashes,
    })
  end

  subject(:cow) { Key.new(priv: Util.keccak256("cow")) }

  describe ".initialize" do
    it "creates EIP-4844 transaction objects" do
      expect(tx).to be_instance_of Tx::Eip4844
    end
  end

  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_y_parity).to eq 1
      expect(tx.signature_r).to eq "cb30e12b313bcb1cd3cd7dd22389d9868db8773132a41c133a41dd9371328fb2"
      expect(tx.signature_s).to eq "74466212ef0d131654a266a6073e99ea589524c1ade64b38025075cc6c35f14f"
    end
  end

  describe ".hex" do
    it "hexes the default transaction" do
      tx.sign(cow)
      expect(tx.hex).to eq "03f8850180800182520894cd2a3d9f938e13cd947ec05abc7fe734df8dd8268080c001e1a0111111111111111111111111111111111111111111111111111111111111111101a0cb30e12b313bcb1cd3cd7dd22389d9868db8773132a41c133a41dd9371328fb2a074466212ef0d131654a266a6073e99ea589524c1ade64b38025075cc6c35f14f"
    end
  end

  describe ".decode" do
    it "decodes the encoded transaction" do
      tx.sign(cow)
      blob_tx = Tx.decode tx.hex
      expect(blob_tx).to be_instance_of Tx::Eip4844
      expect(blob_tx.hex).to eq tx.hex
    end
  end
end
