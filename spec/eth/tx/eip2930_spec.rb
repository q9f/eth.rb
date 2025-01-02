# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Tx::Eip2930 do
  # ref https://goerli.etherscan.io/tx/0xaed08e43736c8c99d6fa3a10b7a66f59a08f0b0999bbf6d050b2f65a5608d988#accesslist
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

  # ref https://goerli.etherscan.io/tx/0xaed08e43736c8c99d6fa3a10b7a66f59a08f0b0999bbf6d050b2f65a5608d988
  subject(:type01) {
    Tx.new({
      chain_id: Chain::GOERLI,
      nonce: 4,
      gas_price: 42 * Unit::GWEI,
      gas_limit: 230_000,
      to: "0xCaA29806044A08E533963b2e573C1230A2cd9a2d",
      value: 0.0137 * Unit::ETHER,
      data: "Foo Bar Ruby Ethereum",
      access_list: list,
    })
  }

  # ref https://goerli.etherscan.io/address/0x4762119a7249823d18aec7eab73258b2d5061dd8
  subject(:testnet) { Key.new(priv: "0xc6c633f85d3f9a4705623b1d9bd1122a1a9196cd53dd352505e895fcbb8452ef") }

  subject(:tx) {
    Tx.new({
      nonce: 0,
      gas_price: Unit::WEI,
      gas_limit: 29_600,
      access_list: list,
    })
  }

  subject(:cow) { Key.new(priv: Util.keccak256("cow")) }

  describe ".decode" do
    it "decodes a known goerli transaction signed by ruby eth gem" do

      # ref https://goerli.etherscan.io/getRawTx?tx=0xaed08e43736c8c99d6fa3a10b7a66f59a08f0b0999bbf6d050b2f65a5608d988
      expected_hex = "0x01f8f605048509c76524008303827094caa29806044a08e533963b2e573c1230a2cd9a2d8730ac13d16c400095466f6f20426172205275627920457468657265756df872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c001a068555b1d5406469aff0fed6eaf1e49087a530c9bb6c79d294376f2c849cedb52a012b1529b344930bc1f3b380c1f31cfe452404f0f7859933776b7e33c8aa1bc6c"
      expected_hash = "0xaed08e43736c8c99d6fa3a10b7a66f59a08f0b0999bbf6d050b2f65a5608d988"
      decoded = Tx.decode(expected_hex)
      expect(decoded.hex).to eq Util.remove_hex_prefix expected_hex
      expect(decoded.hash).to eq Util.remove_hex_prefix expected_hash

      duplicated = Tx.unsigned_copy decoded
      duplicated.sign testnet
      type01.sign testnet

      expect(type01.hex).to eq duplicated.hex
      expect(type01.hash).to eq duplicated.hash
    end
  end

  describe ".initialize" do
    it "creates EIP-2930 transaction objects" do
      expect(tx).to be
      expect(tx).to be_instance_of Tx::Eip2930
    end

    it "doesn't create invalid transaction objects" do
      expect {
        Tx.new({
          nonce: 0,
          gas_price: -9 * Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas price -0.9e10!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT - 1,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 20999!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
          access_list: list,
        })
      }.to raise_error Tx::ParameterError, "Transaction gas limit is too low, try 29600!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT + 1,
          chain_id: Chain::ETHEREUM,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 30000001!"
      expect {
        Tx.new({
          nonce: -1,
          gas_price: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT,
        })
      }.to raise_error Tx::ParameterError, "Invalid signer nonce -1!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT,
          to: "foo",
        })
      }.to raise_error Address::CheckSumError, "Unknown address type foo!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT,
          to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
          value: -1,
        })
      }.to raise_error Tx::ParameterError, "Invalid transaction value -1!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT,
          to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
          value: 1,
          access_list: "bar",
        })
      }.to raise_error Tx::ParameterError, "Invalid access list bar!"
    end
  end

  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_y_parity).to eq 0
      expect(tx.signature_r).to eq "19b12f69aa343e253042851598e77aa7dd3cd2cae03363bc865b4064bffd7184"
      expect(tx.signature_s).to eq "1215becbad16e52044bda5af69e084c888bfad5202817ff5ce244a6b312e47da"
    end

    it "it does not sign a transaction twice" do
      expect { type01.hash }.to raise_error StandardError, "Transaction is not signed!"
      expect(testnet.address.to_s).to eq "0x4762119a7249823D18aec7EAB73258B2D5061Dd8"
      type01.sign(testnet)
      expect { type01.sign(testnet) }.to raise_error StandardError, "Transaction is already signed!"
    end

    it "checks for valid sender" do
      tx_from_cow = Tx.new({
        nonce: 0,
        gas_price: Unit::WEI,
        gas_limit: 29_600,
        from: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
        access_list: list,
      })
      expect {
        tx_from_cow.sign testnet
      }.to raise_error Signature::SignatureError, "Signer does not match sender"
      expect {
        tx_from_cow.sign cow
      }.not_to raise_error
    end
  end

  describe ".encoded" do
    it "encodes the default transaction" do
      expect { tx.encoded }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.encoded).to eq "\x01\xF8\xC0\x01\x80\x01\x82s\xA0\x80\x80\x80\xF8r\xF8Y\x94\xDE\v)Vi\xA9\xFD\x93\xD5\xF2\x8D\x9E\xC8^@\xF4\xCBi{\xAE\xF8B\xA0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\xA0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\a\xD6\x94\xBB\x9B\xC2D\xD7\x98\x12?\xDEx?\xCC\x1Cr\xD3\xBB\x8C\x18\x94\x13\xC0\x80\xA0\x19\xB1/i\xAA4>%0B\x85\x15\x98\xE7z\xA7\xDD<\xD2\xCA\xE03c\xBC\x86[@d\xBF\xFDq\x84\xA0\x12\x15\xBE\xCB\xAD\x16\xE5 D\xBD\xA5\xAFi\xE0\x84\xC8\x88\xBF\xADR\x02\x81\x7F\xF5\xCE$Jk1.G\xDA"
    end

    it "encodes a known goerli transaction" do
      expect { type01.encoded }.to raise_error StandardError, "Transaction is not signed!"
      type01.sign(testnet)
      expect(type01.encoded).to eq "\x01\xF8\xF6\x05\x04\x85\t\xC7e$\x00\x83\x03\x82p\x94\xCA\xA2\x98\x06\x04J\b\xE53\x96;.W<\x120\xA2\xCD\x9A-\x870\xAC\x13\xD1l@\x00\x95Foo Bar Ruby Ethereum\xF8r\xF8Y\x94\xDE\v)Vi\xA9\xFD\x93\xD5\xF2\x8D\x9E\xC8^@\xF4\xCBi{\xAE\xF8B\xA0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\xA0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\a\xD6\x94\xBB\x9B\xC2D\xD7\x98\x12?\xDEx?\xCC\x1Cr\xD3\xBB\x8C\x18\x94\x13\xC0\x01\xA0hU[\x1DT\x06F\x9A\xFF\x0F\xEDn\xAF\x1EI\bzS\f\x9B\xB6\xC7\x9D)Cv\xF2\xC8I\xCE\xDBR\xA0\x12\xB1R\x9B4I0\xBC\x1F;8\f\x1F1\xCF\xE4R@O\x0FxY\x937v\xB7\xE3<\x8A\xA1\xBCl"
    end
  end

  describe ".hex" do
    it "hexes the default transaction" do
      expect { tx.hex }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hex).to eq "01f8c00180018273a0808080f872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c080a019b12f69aa343e253042851598e77aa7dd3cd2cae03363bc865b4064bffd7184a01215becbad16e52044bda5af69e084c888bfad5202817ff5ce244a6b312e47da"
    end

    it "hexes a known goerli transaction" do
      expect { type01.hex }.to raise_error StandardError, "Transaction is not signed!"
      type01.sign(testnet)
      expect(type01.hex).to eq "01f8f605048509c76524008303827094caa29806044a08e533963b2e573c1230a2cd9a2d8730ac13d16c400095466f6f20426172205275627920457468657265756df872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c001a068555b1d5406469aff0fed6eaf1e49087a530c9bb6c79d294376f2c849cedb52a012b1529b344930bc1f3b380c1f31cfe452404f0f7859933776b7e33c8aa1bc6c"
    end
  end

  describe ".hash" do
    it "hashes the default transaction" do
      expect { tx.hash }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hash).to eq "2a9b3ffd67a2b4117fd754c5f9d8561af549c1e8fceb1690c6e4b55af8645736"
    end

    it "hashes a known goerli transaction" do
      expect { type01.hash }.to raise_error StandardError, "Transaction is not signed!"
      type01.sign(testnet)
      expect(type01.hash).to eq "aed08e43736c8c99d6fa3a10b7a66f59a08f0b0999bbf6d050b2f65a5608d988"
    end
  end

  describe ".copy" do
    it "can duplicate transactions" do
      raw = "0x01f8f605048509c76524008303827094caa29806044a08e533963b2e573c1230a2cd9a2d8730ac13d16c400095466f6f20426172205275627920457468657265756df872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c001a068555b1d5406469aff0fed6eaf1e49087a530c9bb6c79d294376f2c849cedb52a012b1529b344930bc1f3b380c1f31cfe452404f0f7859933776b7e33c8aa1bc6c"
      eip2930 = Tx.decode raw
      duplicate = Tx.unsigned_copy eip2930
      expect(eip2930.chain_id).to eq duplicate.chain_id
      expect(eip2930.signer_nonce).to eq duplicate.signer_nonce
      expect(eip2930.gas_price).to eq duplicate.gas_price
      expect(eip2930.gas_limit).to eq duplicate.gas_limit
      expect(eip2930.destination).to eq duplicate.destination
      expect(eip2930.amount).to eq duplicate.amount
      expect(eip2930.payload).to eq duplicate.payload
      expect(eip2930.access_list).to eq duplicate.access_list
      expect(eip2930.type).to eq duplicate.type

      # unsigned
      expect(duplicate.signature_y_parity).not_to be
      expect(duplicate.signature_r).to eq 0
      expect(duplicate.signature_s).to eq 0

      # signed
      duplicate.sign testnet
      expect(eip2930.signature_y_parity).to eq duplicate.signature_y_parity
      expect(eip2930.signature_r).to eq duplicate.signature_r
      expect(eip2930.signature_s).to eq duplicate.signature_s
      expect(duplicate.hex).to eq Util.remove_hex_prefix raw
    end
  end

  context "signing transactions the hard way" do
    it "correctly hashes an unsigned example" do
      sample = Tx.new({
        nonce: 0,
        gas_price: 0x0BA43B7400,
        gas_limit: 0x07b50,
        to: "0x7917bc33eea648809c285607579c9919fb864f8f",
        value: 0x03BAF82D03A000,
        access_list: list,
      })
      lsong = Key.new(priv: "00d862c318d05de0a1c25242c21989e15e35e70c55996fbc4238cd2f2f6a8f62")
      expected_address = Address.new "8d900bfa2353548a4631be870f99939575551b60"

      # a secp256k1 signature over keccak256(0x01 || rlp([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList]))
      expected_sign_data = "01f89d0180850ba43b7400827b50947917bc33eea648809c285607579c9919fb864f8f8703baf82d03a00080f872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c0"
      expected_sign_hash = "81f7bf86cf365f50ef2a9663c4f3001c22394ccd891cd1be8ef59af94d2b1b45"

      # first byte is type 01 as per EIP-2930
      expect(Util.bin_to_hex (sample.unsigned_encoded)[0, 1]).to eq "01"
      expect(Util.bin_to_hex sample.unsigned_encoded).to eq expected_sign_data
      expect(Util.bin_to_hex sample.unsigned_hash).to eq expected_sign_hash

      sample.sign lsong
      expect(Tx.decode(sample.hex).hex).to eq sample.hex
      expect(Tx.decode(sample.hex).hash).to eq sample.hash
    end
  end

  context "different :data input formats" do
    subject(:types) {
      [
        "string",
        "address",
        "bytes32",
        "int256",
      ]
    }
    subject(:args) {
      [
        "Lorem, Ipsum!",
        "0x3ea1e26a2119b038eaf9b27e65cdb401502ae7a4",
        "=\x8B\xFB\x13h\xAE\xE2i>\xB3%\xAF\x9F\x81$K\x190K\b{IA\xA1\xE8\x92\xDAP\xBDH\xDF\xE1",
        -4153010759215853346544872368790226810347211436084119296615430562753409734914,
      ]
    }
    subject(:expected_hex) { "01f90181018001827b508080b8c000000000000000000000000000000000000000000000000000000000000000800000000000000000000000003ea1e26a2119b038eaf9b27e65cdb401502ae7a43d8bfb1368aee2693eb325af9f81244b19304b087b4941a1e892da50bd48dfe1f6d17aad7aff1c87e8481f30395a1595a07b483032affed044e698bf7c43a6fe000000000000000000000000000000000000000000000000000000000000000d4c6f72656d2c20497073756d2100000000000000000000000000000000000000f872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c080a001101750fe4fc89a413e65c7e9ef459180742ef68bda055c35761c84302cad13a037dd31afd4c84fb46fec9120934247662399aa053ce7b5b724275239b15ee3ad" }
    subject(:expected_hash) { "3559540a9e9a228a240643f2f3b3823e5c8ffa41a5d8f37907ea91d50ef59979" }

    it "can create transactions with binary data" do
      abi = Abi.encode types, args
      some = Tx.new({
        nonce: 0,
        gas_price: 1,
        gas_limit: 31_568,
        data: abi,
        access_list: list,
      })

      # expect to properly accept binary data
      some.sign cow
      expect(some.hex).to eq expected_hex
      expect(some.hash).to eq expected_hash

      # expect to match both decoded transaction and decoded abi
      other = Tx.decode some.hex
      expect(other.payload).to eq some.payload
      expect(other.access_list).to eq some.access_list
      expect(other.hex).to eq some.hex
      expect(other.hash).to eq some.hash
      expect(Abi.decode types, some.payload).to eq args
      expect(Abi.decode types, other.payload).to eq args
    end

    it "can create transactions with hexadecimal data" do
      abi = Abi.encode types, args
      hex = Util.bin_to_hex abi
      some = Tx.new({
        nonce: 0,
        gas_price: 1,
        gas_limit: 31_568,
        data: hex,
        access_list: list,
      })

      # expect to properly accept hexadecimal data without changing the transaction hash
      some.sign cow
      expect(some.hex).to eq expected_hex
      expect(some.hash).to eq expected_hash

      # expect to match both decoded transaction and decoded abi
      other = Tx.decode some.hex
      expect(other.payload).to eq some.payload
      expect(other.access_list).to eq some.access_list
      expect(other.hex).to eq some.hex
      expect(other.hash).to eq some.hash
      expect(Abi.decode types, some.payload).to eq args
      expect(Abi.decode types, other.payload).to eq args
    end

    it "can create transactions with ascii data" do
      lorem = "Lorem, Ipsum!"

      # usually libraries prevent that, but in any case this allows to send ascii messages
      some = Tx.new({
        nonce: 0,
        gas_price: 1,
        gas_limit: 29_810,
        data: lorem,
        access_list: list,
      })
      some.sign cow
      expect(some.hex).to eq "01f8cd01800182747280808d4c6f72656d2c20497073756d21f872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c080a017c081b8c851fa7df558054e93539f20b0937aafed06586a2ad59824d52a6f55a00f40033eec8ff5ce9d37270a4170a5d2349142d1f5d0df5064439f60ee6c78be"
      expect(some.hash).to eq "52d5c664c2c2da1970f192a2bc8097f22a77035fceef26a9bd00a00473fe035b"

      # expect to match both decoded transaction and decoded abi
      other = Tx.decode some.hex
      expect(other.payload).to eq some.payload
      expect(other.access_list).to eq some.access_list
      expect(other.hex).to eq some.hex
      expect(other.hash).to eq some.hash

      # same string
      expect(other.payload).to eq lorem
    end
  end
end
