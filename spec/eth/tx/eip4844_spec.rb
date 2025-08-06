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

    it "validates required parameters" do
      expect {
        Tx::Eip4844.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::WEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
          to: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
          blob_versioned_hashes: blob_hashes,
        })
      }.to raise_error Tx::ParameterError, /Invalid max blob fee/
      expect {
        Tx::Eip4844.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::WEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
          to: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
          max_fee_per_blob_gas: Unit::WEI,
        })
      }.to raise_error Tx::ParameterError, /Invalid blob versioned hashes/
      expect {
        Tx::Eip4844.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::WEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
          max_fee_per_blob_gas: Unit::WEI,
          blob_versioned_hashes: blob_hashes,
        })
      }.to raise_error Tx::ParameterError, /Invalid destination address/
    end
  end

  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_y_parity).to eq 1
      expect(tx.signature_r).to eq "cb30e12b313bcb1cd3cd7dd22389d9868db8773132a41c133a41dd9371328fb2"
      expect(tx.signature_s).to eq "74466212ef0d131654a266a6073e99ea589524c1ade64b38025075cc6c35f14f"
    end

    it "does not sign a transaction twice" do
      tx.sign(cow)
      expect { tx.sign(cow) }.to raise_error Signature::SignatureError, "Transaction is already signed!"
    end

    it "checks for a valid sender" do
      tx_from_cow = Tx.new({
        nonce: 0,
        priority_fee: 0,
        max_gas_fee: Unit::WEI,
        gas_limit: Tx::DEFAULT_GAS_LIMIT,
        from: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
        to: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
        max_fee_per_blob_gas: Unit::WEI,
        blob_versioned_hashes: blob_hashes,
      })
      expect {
        tx_from_cow.sign Key.new
      }.to raise_error Signature::SignatureError, "Signer does not match sender"
      expect {
        tx_from_cow.sign cow
      }.not_to raise_error
    end
  end

  describe ".sign_with" do
    it "signs with an external signature" do
      signature = cow.sign(tx.unsigned_hash, tx.chain_id)
      r, s, v = Signature.dissect(signature)
      recovery_id = Chain.to_recovery_id v.to_i(16), tx.chain_id
      tx.sign_with(signature)
      expect(tx.signature_y_parity).to eq recovery_id
      expect(tx.signature_r).to eq r
      expect(tx.signature_s).to eq s
    end

    it "does not sign a transaction twice" do
      signature = cow.sign(tx.unsigned_hash, tx.chain_id)
      tx.sign_with(signature)
      expect { tx.sign_with(signature) }.to raise_error Signature::SignatureError, "Transaction is already signed!"
    end

    it "checks for a valid signer" do
      tx_from_cow = Tx.new({
        nonce: 0,
        priority_fee: 0,
        max_gas_fee: Unit::WEI,
        gas_limit: Tx::DEFAULT_GAS_LIMIT,
        from: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
        to: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
        max_fee_per_blob_gas: Unit::WEI,
        blob_versioned_hashes: blob_hashes,
      })
      signature = Key.new.sign(tx_from_cow.unsigned_hash, tx_from_cow.chain_id)
      expect {
        tx_from_cow.sign_with(signature)
      }.to raise_error Signature::SignatureError, "Signer does not match sender"
    end
  end

  describe ".encoded" do
    it "requires a signature" do
      expect { tx.encoded }.to raise_error Signature::SignatureError, "Transaction is not signed!"
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

    it "parses a real-world raw blob transaction" do
      #ref https://sepolia.etherscan.io/tx/0xc177b7159aba6372bbf296cd7711793324abea797289cf75e72fbd514bd6ce31#blobs
      raw = "0x03f9026783aa36a71184457cd427844852d529826e5294000000000000000000000000000000000000000080b901af7b226f726967696e61746f72223a22566974616c696b204275746572696e222c226465736372697074696f6e223a22416e20696c6c757374726174696f6e206f66206461746120617661696c6162696c6974792073616d706c696e67222c22626c6f6273223a5b7b22636f6e74656e745f74797065223a22746578742f706c61696e222c226465736372697074696f6e223a225468697320626c6f6220636f6e7461696e732061206465736372697074696f6e2074657874206f662074686520696c6c757374726174696f6e2e204974277320612068657820656e636f646564205554462d3820737472696e672e227d2c7b22636f6e74656e745f74797065223a22696d6167652f706e67222c226465736372697074696f6e223a225468697320626c6f6220636f6e7461696e732074686520696c6c757374726174696f6e20696d616765206461746120696e2062617365363420666f726d61742e204974277320612068657820656e636f646564205246432032333937202868747470733a2f2f7777772e7266632d656469746f722e6f72672f7266632f726663323339372920646174612055524c2e227d5d7dc0843fff0321f842a00183be5e67ea6eb79f14071b13f96e51522f1b74566b95a015dd2f7deb9efdaba001b7e9368622cfd553884b59fbce02cee983a43c9d66bc26eca20973570e86e201a08212f42e915611a37dfeb53315232153e161cf5542a72b8cccaebe317e08b867a07b33efe46f58a7f68f5f7d833f205aa994b495ab6c27495530d2c7e7bda71eea"
      blob_tx = Tx.decode raw
      expect(blob_tx).to be_instance_of Tx::Eip4844
      hashes = blob_tx.blob_versioned_hashes.map { |b| Util.bin_to_hex b }
      expect(hashes).to eq [
                             "0183be5e67ea6eb79f14071b13f96e51522f1b74566b95a015dd2f7deb9efdab",
                             "01b7e9368622cfd553884b59fbce02cee983a43c9d66bc26eca20973570e86e2",
                           ]
    end

    it "raises on non-minimal integer encoding" do
      fields = [
        Util.serialize_int_to_big_endian(1),
        "\x00\x01",
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        "",
        Util.serialize_int_to_big_endian(1),
        "",
        [],
        Util.serialize_int_to_big_endian(1),
        [],
      ]
      encoded = Rlp.encode(fields)
      hex = "0x03#{Util.bin_to_hex(encoded)}"
      expect { Tx::Eip4844.decode(hex) }.to raise_error Rlp::DeserializationError
    end

    it "round-trips valid integer encoding" do
      fields = [
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        "",
        Util.serialize_int_to_big_endian(1),
        "",
        [],
        Util.serialize_int_to_big_endian(1),
        [],
      ]
      encoded = Rlp.encode(fields)
      hex = "0x03#{Util.bin_to_hex(encoded)}"
      tx = Tx::Eip4844.decode(hex)
      expect(tx.signer_nonce).to eq 1
    end

    it "raises when field count is invalid" do
      fields = [
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        Util.serialize_int_to_big_endian(1),
        "",
        Util.serialize_int_to_big_endian(1),
        "",
        [],
        Util.serialize_int_to_big_endian(1),
        [],
        "",
      ]
      encoded = Rlp.encode(fields)
      hex = "0x03#{Util.bin_to_hex(encoded)}"
      expect { Tx::Eip4844.decode(hex) }.to raise_error Tx::DecoderError
    end
  end

  describe ".copy" do
    it "can duplicate transactions" do
      tx.sign(cow)
      duplicated = Tx::Eip4844.unsigned_copy tx
      expect(duplicated.signature_r).to eq 0
      expect(duplicated.type).to eq Tx::TYPE_4844
    end

    it "raises on wrong transaction type" do
      wrong = Tx.new({ nonce: 0, priority_fee: 0, max_gas_fee: Unit::WEI, gas_limit: Tx::DEFAULT_GAS_LIMIT })
      expect { Tx::Eip4844.unsigned_copy wrong }.to raise_error Tx::TransactionTypeError
    end
  end
end
