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

  #ref https://sepolia.etherscan.io/tx/0xab41e0e5bd3cc0415b441b57c3d9ec2d0547c9f34859e4136e5042ae7f7e20ea#accesslist
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
        "0xc122f8378c32ba5acd599ec43fe6f6e264c1abae",
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
        "0x00d627057cd4ba50f9c6bde33eee3ef1183df885",
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

  # ref https://sepolia.etherscan.io/getRawTx?tx=0xab41e0e5bd3cc0415b441b57c3d9ec2d0547c9f34859e4136e5042ae7f7e20ea
  subject(:type04_hex) { "0x04f9036883aa36a70183603cb884193dca90830391b494c122f8378c32ba5acd599ec43fe6f6e264c1abae80b90184a6d0ad6100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000cb98643b8786950f0461f3b0edf99d88f274574d00000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000d2135cfb216b74109775236e36d4b433f1df507b00000000000000000000000000000000000000000000000000071afd498d00000000000000000000000000000000000000000000000000000000000000000000f8b7f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694c122f8378c32ba5acd599ec43fe6f6e264c1abaec0d694cb98643b8786950f0461f3b0edf99d88f274574dc0d694d2135cfb216b74109775236e36d4b433f1df507bc0d69400d627057cd4ba50f9c6bde33eee3ef1183df885c0f8bbf85d83aa36a79400d627057cd4ba50f9c6bde33eee3ef1183df8850201a01003c672e470c801843fcdedcd6b0f4b5de35e878c3d3c0dd936003129adcf0ba04ba06410153cda14be60e336a8db39596ac0c5ef31b0aae70ab323527b48a3d6f85a019400d627057cd4ba50f9c6bde33eee3ef1183df8850180a0f927b261e29065e03948c4ace50b4c559c2fc8606b37ed8b6dd74c6485fc5b6fa06b93cff0d9d30d2c9c4e1307ed10531d33fd9d0a276969512a0bc84100a043af01a0768999a42a29b8659a00b19928f1fa176e0bde5a2d38a24988efbef0ab576a42a07aea2fd7cf85d5484ad71feb2cbdfd3f5403a85665b45eca294cc06e83ccf2b6" }
  # ref https://sepolia.etherscan.io/tx/0xab41e0e5bd3cc0415b441b57c3d9ec2d0547c9f34859e4136e5042ae7f7e20ea
  subject(:type04_hash) { "0xab41e0e5bd3cc0415b441b57c3d9ec2d0547c9f34859e4136e5042ae7f7e20ea" }

  subject(:testnet) { Key.new(priv: "0xe2ae7e9acc42a836921f1c2a5fb9b72f8450bd386035302522fcce19bfefaa20") }

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
  describe ".initialize" do
    it "creates EIP-7702 transaction objects" do
      expect(tx).to be
      expect(tx).to be_instance_of Tx::Eip7702
    end

    it "doesn't create invalid transaction objects" do
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: -9,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::DEFAULT_GAS_LIMIT,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid gas priority fee -9!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: -9 * Unit::GWEI,
                 gas_limit: Tx::DEFAULT_GAS_LIMIT,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid max gas fee -0.9e10!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::DEFAULT_GAS_LIMIT - 1,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 20999!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::DEFAULT_GAS_LIMIT,
                 access_list: access_list,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Transaction gas limit is too low, try 36800!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::BLOCK_GAS_LIMIT + 1,
                 chain_id: Chain::ETHEREUM,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 30000001!"
      expect {
        Tx.new({
                 nonce: -1,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::BLOCK_GAS_LIMIT,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid signer nonce -1!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::BLOCK_GAS_LIMIT,
                 to: "foo",
                 authorization_list: authorization_list,
               })
      }.to raise_error Address::CheckSumError, "Unknown address type foo!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::BLOCK_GAS_LIMIT,
                 to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
                 value: -1,
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid transaction value -1!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::BLOCK_GAS_LIMIT,
                 to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
                 value: 1,
                 access_list: "bar",
                 authorization_list: authorization_list,
               })
      }.to raise_error Tx::ParameterError, "Invalid access list bar!"
      expect {
        Tx.new({
                 nonce: 0,
                 priority_fee: 0,
                 max_gas_fee: Unit::GWEI,
                 gas_limit: Tx::BLOCK_GAS_LIMIT,
                 to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
                 value: 1,
                 access_list: access_list,
                 authorization_list: "bar",
               })
      }.to raise_error Tx::ParameterError, "Invalid authorization list bar!"
    end
  end

  describe "Authorization" do
  end
  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_y_parity).to eq 0
      expect(tx.signature_r).to eq "6f5284af183d53d59a68880068be6cee4ba8c559b944827a1961db691e7d76a9"
      expect(tx.signature_s).to eq "517deec535776476bea90cfadc5b8c67be63760912ae840f896a4d7b88eda522"
    end

    it "it does not sign a transaction twice" do
      expect { type04.hash }.to raise_error StandardError, "Transaction is not signed!"
      expect(testnet.address.to_s).to eq "0xC122F8378C32bA5AcD599Ec43FE6f6e264c1abAE"
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
      expect(tx.encoded).to eq "\x04\xF9\x01\x0A\x01\x80\x80\x01\x82\x52\x08\x80\x80\x80\xC0\xF8\xBA\xF8\x5C\x82\x7A\x69\x94\x70\x0B\x6A\x60\xCE\x7E\xAA\xEA\x56\xF0\x65\x75\x3D\x8D\xCB\x96\x53\xDB\xAD\x35\x02\x80\xA0\xA4\xF2\xC5\x24\x3C\x3D\x6D\x82\x16\x8E\xF3\x5B\x3D\x3D\xF1\xE5\x0C\xEF\xEE\x1B\xC2\x12\xC7\x69\xBD\x19\x68\x06\x1C\x39\x52\x60\xA0\x7F\x34\x6C\x18\x04\x30\x0B\x96\xD6\x87\xA9\x0C\xE5\xBC\xEA\x08\x83\xC1\x2B\xC4\x5B\x6A\x8A\x29\x4E\x29\xFF\x7C\x02\xB4\x2A\x65\xF8\x5A\x01\x94\x70\x0B\x6A\x60\xCE\x7E\xAA\xEA\x56\xF0\x65\x75\x3D\x8D\xCB\x96\x53\xDB\xAD\x35\x0B\x80\xA0\xAC\xEC\x76\xE8\x44\x69\x0C\xF2\xF5\x83\x17\xD1\x3D\x91\x0B\x27\x0C\xF0\xB9\xE3\x07\xDB\x80\x94\x40\x2D\xC4\x6B\x4F\x45\x6A\x81\xA0\x57\x0D\x6E\xA1\x63\xA5\x05\x89\x6A\xA2\x67\x4D\x56\x81\x00\x33\xCD\x4D\x03\xB1\x37\x87\x06\x5B\x5A\xBE\x57\xCD\xE4\x85\xE5\x2A\x80\xA0\x6F\x52\x84\xAF\x18\x3D\x53\xD5\x9A\x68\x88\x00\x68\xBE\x6C\xEE\x4B\xA8\xC5\x59\xB9\x44\x82\x7A\x19\x61\xDB\x69\x1E\x7D\x76\xA9\xA0\x51\x7D\xEE\xC5\x35\x77\x64\x76\xBE\xA9\x0C\xFA\xDC\x5B\x8C\x67\xBE\x63\x76\x09\x12\xAE\x84\x0F\x89\x6A\x4D\x7B\x88\xED\xA5\x22"
    end
  end

  describe ".hex" do
    it "hexes the default transaction" do
      expect { tx.hex }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hex).to eq "04f9010a01808001825208808080c0f8baf85c827a6994700b6a60ce7eaaea56f065753d8dcb9653dbad350280a0a4f2c5243c3d6d82168ef35b3d3df1e50cefee1bc212c769bd1968061c395260a07f346c1804300b96d687a90ce5bcea0883c12bc45b6a8a294e29ff7c02b42a65f85a0194700b6a60ce7eaaea56f065753d8dcb9653dbad350b80a0acec76e844690cf2f58317d13d910b270cf0b9e307db8094402dc46b4f456a81a0570d6ea163a505896aa2674d56810033cd4d03b13787065b5abe57cde485e52a80a06f5284af183d53d59a68880068be6cee4ba8c559b944827a1961db691e7d76a9a0517deec535776476bea90cfadc5b8c67be63760912ae840f896a4d7b88eda522"
    end

    it "hexes a known transaction " do
      eip7702 = Tx.decode type04_hex
      expect("0x#{eip7702.hex}").to eq type04_hex
    end
  end

  describe ".hash" do
    it "hashes the default transaction" do
      expect { tx.hash }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hash).to eq "db6b7963d03c307a9ece60faddfbad39a7b15d66963dc835114989600342cd7b"
    end

    it "hashes a known transaction" do
      eip7702 = Tx.decode type04_hex
      expect("0x#{eip7702.hash}").to eq type04_hash
    end
  end

  describe ".copy" do
    it "can duplicate transactions" do
      eip7702 = Tx.decode type04_hex
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

      #unsigned
      expect(duplicate.signature_y_parity).not_to be
      expect(duplicate.signature_r).to eq 0
      expect(duplicate.signature_s).to eq 0

      # signed
      duplicate.sign testnet

      expect(eip7702.signature_r).to eq duplicate.signature_r
      expect(eip7702.signature_s).to eq duplicate.signature_s
      expect(eip7702.signature_y_parity).to eq duplicate.signature_y_parity
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
        [],
      ]
      encoded = Rlp.encode(fields)
      hex = "0x04#{Util.bin_to_hex(encoded)}"
      expect { Tx::Eip7702.decode(hex) }.to raise_error Rlp::DeserializationError
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
        [],
      ]
      encoded = Rlp.encode(fields)
      hex = "0x04#{Util.bin_to_hex(encoded)}"
      tx = Tx::Eip7702.decode(hex)
      expect(tx.signer_nonce).to eq 1
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
