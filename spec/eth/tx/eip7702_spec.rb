# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Tx::Eip7702 do
  subject(:anvil) {
    31337.freeze
  }

  subject(:authorization_list) {
    [
      Tx::Eip7702::Authorization.new(
        chain_id: anvil,
        address: "700b6a60ce7eaaea56f065753d8dcb9653dbad35",
        nonce: 2,
        recovery_id: 0,
        r: "a4f2c5243c3d6d82168ef35b3d3df1e50cefee1bc212c769bd1968061c395260",
        s: "7f346c1804300b96d687a90ce5bcea0883c12bc45b6a8a294e29ff7c02b42a65",
      ),
      Tx::Eip7702::Authorization.new(
        chain_id: Chain::ETHEREUM,
        address: "700b6a60ce7eaaea56f065753d8dcb9653dbad35",
        nonce: 11,
        r: "acec76e844690cf2f58317d13d910b270cf0b9e307db8094402dc46b4f456a81",
        s: "570d6ea163a505896aa2674d56810033cd4d03b13787065b5abe57cde485e52a",
        recovery_id: 0,
      ),
    ]
  }

  subject(:unsigned_authorization) {
    Tx::Eip7702::Authorization.new(
      chain_id: anvil,
      address: "700b6a60ce7eaaea56f065753d8dcb9653dbad35",
      nonce: 2,
    )
  }

  subject(:unsigned_cow_authorization) {
    Tx::Eip7702::Authorization.new(
      chain_id: anvil,
      address: cow.address.to_s,
      nonce: 2,
    )
  }
  subject(:access_list) {
    [
      [
        "de0b295669a9fd93d5f28d9ec85e40f4cb697bae",
        [
          "0000000000000000000000000000000000000000000000000000000000000003",
          "0000000000000000000000000000000000000000000000000000000000000007",
        ],
      ],
      [
        "0xa0ee7a142d267c1f36714e4a8f75612f20a79720",
        [],
      ],
      [
        "0xcb98643b8786950f0461f3b0edf99d88f274574d",
        [],
      ],
      [
        "0xd2135cfb216b74109775236e36d4b433f1df507b",
        [],
      ],
      [
        "0x700b6a60ce7eaaea56f065753d8dcb9653dbad35",
        [],
      ],
    ]
  }

  subject(:type04) {
    Tx.new({
             chain_id: anvil,
             nonce: 1,
             priority_fee: 1000000000,
             max_gas_fee: 2200000000,
             gas_limit: 554330,
             to: "0xa0ee7a142d267c1f36714e4a8f75612f20a79720",
             value: 0,
             data: "0xa6d0ad6100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000cb98643b8786950f0461f3b0edf99d88f274574d00000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000d2135cfb216b74109775236e36d4b433f1df507b00000000000000000000000000000000000000000000000000071afd498d00000000000000000000000000000000000000000000000000000000000000000000",
             access_list: access_list,
             authorization_list: authorization_list,
           })
  }

  subject(:signed) {
    tx = Tx.new({
      chain_id: anvil,
      nonce: 1,
      priority_fee: 1000000000,
      max_gas_fee: 2200000000,
      gas_limit: 554330,
      to: "0xa0ee7a142d267c1f36714e4a8f75612f20a79720",
      value: 0,
      data: "0xa6d0ad6100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000cb98643b8786950f0461f3b0edf99d88f274574d00000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000d2135cfb216b74109775236e36d4b433f1df507b00000000000000000000000000000000000000000000000000071afd498d00000000000000000000000000000000000000000000000000000000000000000000",
      access_list: access_list,
      authorization_list: authorization_list,
    })
    tx.sign(cow)
    tx
  }
  subject(:testnet) { Key.new(priv: "0xc6c633f85d3f9a4705623b1d9bd1122a1a9196cd53dd352505e895fcbb8452ef") }

  subject(:tx) {
    Tx.new({
             nonce: 0,
             priority_fee: 0,
             max_gas_fee: Unit::WEI,
             gas_limit: Tx::DEFAULT_GAS_LIMIT,
             authorization_list: authorization_list,
           })
  }

  subject(:cow) { Key.new(priv: Util.keccak256("cow")) }
  subject(:dog) { Key.new(priv: Util.keccak256("dog")) }
  subject(:dog_tx) {
    tx = Tx.new({
                  chain_id: anvil,
                  nonce: 1,
                  priority_fee: 1000000000,
                  max_gas_fee: 2200000000,
                  gas_limit: 554330,
                  from: dog.address,
                  to: "0xa0ee7a142d267c1f36714e4a8f75612f20a79720",
                  value: 0,
                  data: "0xa6d0ad6100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000cb98643b8786950f0461f3b0edf99d88f274574d00000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000d2135cfb216b74109775236e36d4b433f1df507b00000000000000000000000000000000000000000000000000071afd498d00000000000000000000000000000000000000000000000000000000000000000000",
                  access_list: access_list,
                  authorization_list: authorization_list,
                })
  }
  subject(:type04_hex) {
    "\x4\xf9\x1\xa\x1\x80\x80\x1\x82\x52\x8\x80\x80\x80\xc0\xf8\xba\xf8\x5c\x82\x7a\x69\x94\x70\xb\x6a\x60\xce\x7e\xaa\xea\x56\xf0\x65\x75\x3d\x8d\xcb\x96\x53\xdb\xad\x35\x2\x80\xa0\xa4\xf2\xc5\x24\x3c\x3d\x6d\x82\x16\x8e\xf3\x5b\x3d\x3d\xf1\xe5\xc\xef\xee\x1b\xc2\x12\xc7\x69\xbd\x19\x68\x6\x1c\x39\x52\x60\xa0\x7f\x34\x6c\x18\x4\x30\xb\x96\xd6\x87\xa9\xc\xe5\xbc\xea\x8\x83\xc1\x2b\xc4\x5b\x6a\x8a\x29\x4e\x29\xff\x7c\x2\xb4\x2a\x65\xf8\x5a\x1\x94\x70\xb\x6a\x60\xce\x7e\xaa\xea\x56\xf0\x65\x75\x3d\x8d\xcb\x96\x53\xdb\xad\x35\xb\x80\xa0\xac\xec\x76\xe8\x44\x69\xc\xf2\xf5\x83\x17\xd1\x3d\x91\xb\x27\xc\xf0\xb9\xe3\x7\xdb\x80\x94\x40\x2d\xc4\x6b\x4f\x45\x6a\x81\xa0\x57\xd\x6e\xa1\x63\xa5\x5\x89\x6a\xa2\x67\x4d\x56\x81\x0\x33\xcd\x4d\x3\xb1\x37\x87\x6\x5b\x5a\xbe\x57\xcd\xe4\x85\xe5\x2a\x80\xa0\x1a\x82\xa3\x58\x41\x30\x56\x39\xf0\x45\x70\xd2\x10\xf2\xb8\x8e\xd7\xaf\x20\xd9\x51\xb3\x2\xb\x28\x37\x5f\x24\x5d\x1e\xdf\x28\xa0\x35\x9d\x4e\x56\x34\x77\x4b\xe\x25\xc9\x13\xdb\x88\xb2\xf\xec\x8d\xd\xcd\x29\x78\x8d\xa4\xc7\x1e\x9a\x82\x72\x2a\x69\x20\xf5"
  }
  describe ".initialize" do
    it "creates EIP-7702 transaction objects" do
      expect(tx).to be
      expect(tx).to be_instance_of Tx::Eip7702
    end

    it "doesn't create invalid transaction objects"
  end

  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_y_parity).to eq 0
      expect(tx.signature_r).to eq "1a82a35841305639f04570d210f2b88ed7af20d951b3020b28375f245d1edf28"
      expect(tx.signature_s).to eq "359d4e5634774b0e25c913db88b20fec8d0dcd29788da4c71e9a82722a6920f5"
    end

    it "it does not sign a transaction twice" do
      expect { type04.hash }.to raise_error StandardError, "Transaction is not signed!"
      expect(testnet.address.to_s).to eq "0x4762119a7249823D18aec7EAB73258B2D5061Dd8"
      type04.sign(testnet)
      expect { type04.sign(testnet) }.to raise_error StandardError, "Transaction is already signed!"
    end

    it "checks for a valid sender" do
      expect { dog_tx.sign(cow) }.to raise_error StandardError, "Signer does not match sender"
    end
  end

  describe ".encoded" do
    it "encodes the default transaction" do
      expect { tx.encoded }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)

      expect(tx.encoded).to eq "\x4\xf9\x1\xa\x1\x80\x80\x1\x82\x52\x8\x80\x80\x80\xc0\xf8\xba\xf8\x5c\x82\x7a\x69\x94\x70\xb\x6a\x60\xce\x7e\xaa\xea\x56\xf0\x65\x75\x3d\x8d\xcb\x96\x53\xdb\xad\x35\x2\x80\xa0\xa4\xf2\xc5\x24\x3c\x3d\x6d\x82\x16\x8e\xf3\x5b\x3d\x3d\xf1\xe5\xc\xef\xee\x1b\xc2\x12\xc7\x69\xbd\x19\x68\x6\x1c\x39\x52\x60\xa0\x7f\x34\x6c\x18\x4\x30\xb\x96\xd6\x87\xa9\xc\xe5\xbc\xea\x8\x83\xc1\x2b\xc4\x5b\x6a\x8a\x29\x4e\x29\xff\x7c\x2\xb4\x2a\x65\xf8\x5a\x1\x94\x70\xb\x6a\x60\xce\x7e\xaa\xea\x56\xf0\x65\x75\x3d\x8d\xcb\x96\x53\xdb\xad\x35\xb\x80\xa0\xac\xec\x76\xe8\x44\x69\xc\xf2\xf5\x83\x17\xd1\x3d\x91\xb\x27\xc\xf0\xb9\xe3\x7\xdb\x80\x94\x40\x2d\xc4\x6b\x4f\x45\x6a\x81\xa0\x57\xd\x6e\xa1\x63\xa5\x5\x89\x6a\xa2\x67\x4d\x56\x81\x0\x33\xcd\x4d\x3\xb1\x37\x87\x6\x5b\x5a\xbe\x57\xcd\xe4\x85\xe5\x2a\x80\xa0\x1a\x82\xa3\x58\x41\x30\x56\x39\xf0\x45\x70\xd2\x10\xf2\xb8\x8e\xd7\xaf\x20\xd9\x51\xb3\x2\xb\x28\x37\x5f\x24\x5d\x1e\xdf\x28\xa0\x35\x9d\x4e\x56\x34\x77\x4b\xe\x25\xc9\x13\xdb\x88\xb2\xf\xec\x8d\xd\xcd\x29\x78\x8d\xa4\xc7\x1e\x9a\x82\x72\x2a\x69\x20\xf5"
    end

    it "encodes a known transaction - pending until testnets are live"
  end

  describe ".hex" do
    it "hexes the default transaction" do
      expect { tx.hex }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hex).to eq "04f9010a01808001825208808080c0f8baf85c827a6994700b6a60ce7eaaea56f065753d8dcb9653dbad350280a0a4f2c5243c3d6d82168ef35b3d3df1e50cefee1bc212c769bd1968061c395260a07f346c1804300b96d687a90ce5bcea0883c12bc45b6a8a294e29ff7c02b42a65f85a0194700b6a60ce7eaaea56f065753d8dcb9653dbad350b80a0acec76e844690cf2f58317d13d910b270cf0b9e307db8094402dc46b4f456a81a0570d6ea163a505896aa2674d56810033cd4d03b13787065b5abe57cde485e52a80a01a82a35841305639f04570d210f2b88ed7af20d951b3020b28375f245d1edf28a0359d4e5634774b0e25c913db88b20fec8d0dcd29788da4c71e9a82722a6920f5"
    end

    it "hexes a known transaction - pending until testnets are live"
  end

  describe ".hash" do
    it "hashes the default transaction" do
      expect { tx.hash }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hash).to eq "909ec5f61d2bc645db07001dc27a8aab48caa15b408f229ab5d053c7d4ea5cf7"
    end

    it "hashes a known transaction - pending until testnets are live"
  end

  describe ".copy" do
    it "can duplicate transactions" do
      duplicate = Tx.unsigned_copy signed
      expect(signed.chain_id).to eq duplicate.chain_id
      expect(signed.signer_nonce).to eq duplicate.signer_nonce
      expect(signed.max_priority_fee_per_gas).to eq duplicate.max_priority_fee_per_gas
      expect(signed.max_fee_per_gas).to eq duplicate.max_fee_per_gas
      expect(signed.gas_limit).to eq duplicate.gas_limit
      expect(signed.destination).to eq duplicate.destination
      expect(signed.amount).to eq duplicate.amount
      expect(signed.payload).to eq duplicate.payload
      expect(signed.access_list).to eq duplicate.access_list
      expect(signed.type).to eq duplicate.type
      expect(signed.authorization_list).to eq duplicate.authorization_list

      #unsigned
      expect(duplicate.signature_y_parity).not_to be
      expect(duplicate.signature_r).to eq 0
      expect(duplicate.signature_s).to eq 0

      # signed
      duplicate.sign cow
      expect(signed.signature_y_parity).to eq duplicate.signature_y_parity
      expect(signed.signature_r).to eq duplicate.signature_r
      expect(signed.signature_s).to eq duplicate.signature_s
    end

    it "can duplicate a known transaction" do
      eip7702 = Tx.decode signed.hex
      duplicate = Tx.unsigned_copy eip7702
      expect(eip7702.chain_id).to eq duplicate.chain_id
      expect(eip7702.signer_nonce).to eq duplicate.signer_nonce
      expect(eip7702.max_priority_fee_per_gas).to eq duplicate.max_priority_fee_per_gas
      expect(eip7702.max_fee_per_gas).to eq duplicate.max_fee_per_gas
      expect(eip7702.gas_limit).to eq duplicate.gas_limit
      expect(eip7702.destination).to eq duplicate.destination
      expect(eip7702.amount).to eq duplicate.amount
      expect(eip7702.payload).to eq duplicate.payload
      expect(eip7702.access_list).to eq duplicate.access_list
      expect(eip7702.type).to eq duplicate.type
      expect(eip7702.authorization_list).to eq duplicate.authorization_list
    end

    it "can decode an unsigned transaction" do
      eip7702 = Tx.decode signed.hex
      duplicate = Tx.unsigned_copy eip7702
      decoded = Tx.decode Util.bin_to_hex duplicate.unsigned_encoded
      expect(decoded.signature_y_parity).to be nil
      expect(decoded.signature_r).to be 0
      expect(decoded.signature_s).to be 0
    end

    it "can duplicate a known transaction - pending until testnets are live"
  end

  describe ".decode" do
    subject(:transaction_data_missing_the_last_field) {
      # take the valid hex from a signed transaction, drop the last field from the data, then re-wrap that as a transaction.
      hex = signed.hex
      bin = Util.hex_to_bin hex[2..]
      tx = Rlp.decode bin
      tx = tx[0..-2]
      tx_encoded = Rlp.encode tx
      # create an EIP-2718 envelope with EIP-7702 type payload
      tx_type = Util.serialize_int_to_big_endian Tx::TYPE_7702

      # return the hex version ready for working with
      Util.bin_to_hex "#{tx_type}#{tx_encoded}"
    }

    it "gives an error when the transaction is missing a signature field" do
      expect { Tx::Eip7702.decode(transaction_data_missing_the_last_field) }.to raise_error Eth::Tx::DecoderError, "Cannot decode EIP-7702 payload!"
    end
  end

  describe "Authorization" do
    describe ".sign" do
      it "does not allow signing of an already signed authorization" do
        expect { authorization_list.first.sign cow }.to raise_error Signature::SignatureError, "Authorization is already signed!"
      end

      it "requires the address to match the signing key" do
        expect { unsigned_authorization.sign cow }.to raise_error Signature::SignatureError, "Signer does not match sender"
      end

      it "updates the y parity, r and s correctly" do
        unsigned_cow_authorization.sign cow

        expect(unsigned_cow_authorization.signature_y_parity).to eq 1
        expect(unsigned_cow_authorization.signature_r).to eq "66cadb13ae65792aaee7c9af01efb056ea3e6d8e14c8ab2dd398d429a645e042"
        expect(unsigned_cow_authorization.signature_s).to eq "24d8959748c1cd7e31759b210d8617af6c9709e3b2df22fdfe5f72cabfab04ed"
      end
    end
  end
end
