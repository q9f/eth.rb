# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Tx::Legacy do
  subject(:tx) {
    Tx.new({
      nonce: 0,
      gas_price: Unit::WEI,
      gas_limit: Tx::DEFAULT_GAS_LIMIT,
    })
  }
  subject(:cow) { Key.new(priv: Util.keccak256("cow")) }

  # ref https://goerli.etherscan.io/tx/0x1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1
  subject(:legacy) {
    Tx.new(
      {
        nonce: 1,
        gas_price: 40 * Unit::GWEI,
        gas_limit: 21576,
        to: "0xcaa29806044a08e533963b2e573c1230a2cd9a2d",
        value: BigDecimal("0.123456789012345678") * Unit::ETHER,
        data: "Lorem Ipsum Ruby Ethereum Test 1-2-3",
      },
      Chain::GOERLI
    )
  }

  # ref https://goerli.etherscan.io/tx/0x047e319fc8e587a77f6e9a13c30d90b5a741d93e8b35a54b12c91d6149eda359
  subject(:ruby) {
    Tx.new(
      {
        nonce: 3,
        gas_price: 42 * Unit::GWEI,
        gas_limit: 23_000,
        to: "0xCaA29806044A08E533963b2e573C1230A2cd9a2d",
        value: 0.0069 * Unit::ETHER,
        data: "Foo Bar Ruby Ethereum",
      },
      Chain::GOERLI
    )
  }

  # ref https://goerli.etherscan.io/address/0x4762119a7249823d18aec7eab73258b2d5061dd8
  subject(:testnet) { Key.new(priv: "0xc6c633f85d3f9a4705623b1d9bd1122a1a9196cd53dd352505e895fcbb8452ef") }

  describe ".decode" do
    it "decodes the first mainnet transaction" do

      # ref https://etherscan.io/tx/0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060
      expected_hex = "f86780862d79883d2000825208945df9b87991262f6ba471f09758cde1c0fc1de734827a69801ca088ff6cf0fefd94db46111149ae4bfc179e9b94721fffd821d38d16464b3f71d0a045e0aff800961cfce805daef7016b9b675c137a6a41a548f7b60a3484c06a33a"
      expected_hash = "5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060"
      tx = Tx.decode(expected_hex)
      expect(tx.hex).to eq expected_hex
      expect(tx.hash).to eq expected_hash
    end

    it "decodes a low-gas mainnet transaction" do

      # ref https://etherscan.io/tx/0x1de3026bb6be99d36d2d263fdfa33c92705ec3a69b4a3577b9983168a6653d9c
      expected_hex = "f869018504a817c8008301daa094fe4fa55500bf397ef429021455c6a95f65a01b3c808441c0e1b51ba034d0434d6f032d982ad4e3b4ae79cd6455f1d13dd3b257b9c2ed3a95e48753c1a036e04c480078005be9c94a2eb4afbb36e8605ce80d809413355769cedf694be2"
      expected_hash = "1de3026bb6be99d36d2d263fdfa33c92705ec3a69b4a3577b9983168a6653d9c"
      tx = Tx.decode(expected_hex)
      expect(tx.hex).to eq expected_hex
      expect(tx.hash).to eq expected_hash
    end

    it "decodes a known goerli transaction" do

      # ref https://goerli.etherscan.io/tx/0x1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1
      expected_hex = "f890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
      expected_hash = "1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1"
      tx = Tx.decode(expected_hex)
      expect(tx.hex).to eq expected_hex
      expect(tx.hash).to eq expected_hash
    end

    it "decodes a known goerli transaction signed by ruby eth gem" do

      # ref https://goerli.etherscan.io/getRawTx?tx=0x047e319fc8e587a77f6e9a13c30d90b5a741d93e8b35a54b12c91d6149eda359
      expected_hex = "0xf880038509c76524008259d894caa29806044a08e533963b2e573c1230a2cd9a2d8718838370f3400095466f6f20426172205275627920457468657265756d2ea0a0133bf9a770032e18a2ce0eda0d8562abbd88920d696d02373e901967f9956da075e6ce3e86db8391524a7dff0331e90c2bf18cedfbd4164f177a86c53e5be4fa"
      expected_hash = "0x047e319fc8e587a77f6e9a13c30d90b5a741d93e8b35a54b12c91d6149eda359"
      decoded = Tx.decode(expected_hex)
      expect(decoded.hex).to eq Util.remove_hex_prefix expected_hex
      expect(decoded.hash).to eq Util.remove_hex_prefix expected_hash

      duplicated = Tx.unsigned_copy decoded
      duplicated.sign testnet
      ruby.sign testnet

      expect(ruby.hex).to eq duplicated.hex
      expect(ruby.hash).to eq duplicated.hash
    end
  end

  describe ".initialize" do
    it "creates legacy transaction objects" do
      expect(Tx.new({
        nonce: 0,
        gas_price: Unit::GWEI,
        gas_limit: Tx::DEFAULT_GAS_LIMIT,
      })).to be
      expect(Tx.new({
        nonce: 0,
        gas_price: Unit::GWEI,
        gas_limit: Tx::DEFAULT_GAS_LIMIT,
      })).to be_instance_of Tx::Legacy
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
          gas_limit: Tx::BLOCK_GAS_LIMIT + 1,
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
    end
  end

  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_v).to eq "25"
      expect(tx.signature_r).to eq "2b1060357c41cdd7e469efbef7efa857c785229296e497e5784bdd58d69c1f68"
      expect(tx.signature_s).to eq "58d20fcf6d8700ccf1185ad51f03097f9670281b5720ba98485a64841095ae16"
    end

    it "it does not sign a transaction twice" do
      expect { legacy.hash }.to raise_error StandardError, "Transaction is not signed!"
      expect(testnet.address.to_s).to eq "0x4762119a7249823D18aec7EAB73258B2D5061Dd8"
      legacy.sign(testnet)
      expect { legacy.sign(testnet) }.to raise_error StandardError, "Transaction is already signed!"
    end

    it "checks for valid sender" do
      tx_from_cow = Tx.new({
        nonce: 0,
        gas_price: Unit::WEI,
        gas_limit: Tx::DEFAULT_GAS_LIMIT,
        from: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826",
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
      expect(tx.encoded).to eq "\xF8K\x80\x01\x82R\b\x80\x80\x80%\xA0+\x10`5|A\xCD\xD7\xE4i\xEF\xBE\xF7\xEF\xA8W\xC7\x85\"\x92\x96\xE4\x97\xE5xK\xDDX\xD6\x9C\x1Fh\xA0X\xD2\x0F\xCFm\x87\x00\xCC\xF1\x18Z\xD5\x1F\x03\t\x7F\x96p(\eW \xBA\x98HZd\x84\x10\x95\xAE\x16"
    end

    it "encodes a known goerli transaction" do
      expect { legacy.encoded }.to raise_error StandardError, "Transaction is not signed!"
      legacy.sign(testnet)
      expect(legacy.encoded).to eq "\xF8\x90\x01\x85\tP/\x90\x00\x82TH\x94\xCA\xA2\x98\x06\x04J\b\xE53\x96;.W<\x120\xA2\xCD\x9A-\x88\x01\xB6\x9BK\xA60\xF3N\xA4Lorem Ipsum Ruby Ethereum Test 1-2-3.\xA0\xFBM0\x8F=?\x97p\xF2e.\xF4\x0E\xA86\x9A\xB3r\xE5\x9B\xAD\x81O\xB2'\xFA\xE1\xFD\xFD\xFAM:\xA0f\xC8\xA2\xA2\xA2\xAB\xCD9\e\xAC\x869\x99Z\x10\xF1Tj\x87>\xF5\xB4R\xBF\xE5\xFC6y\x01\xD9\xF4\xAB"
    end
  end

  describe ".hex" do
    it "hexes the default transaction" do
      expect { tx.hex }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hex).to eq "f84b800182520880808025a02b1060357c41cdd7e469efbef7efa857c785229296e497e5784bdd58d69c1f68a058d20fcf6d8700ccf1185ad51f03097f9670281b5720ba98485a64841095ae16"
    end

    it "hexes a known goerli transaction" do
      expect { legacy.hex }.to raise_error StandardError, "Transaction is not signed!"
      legacy.sign(testnet)
      expect(legacy.hex).to eq "f890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
    end
  end

  describe ".hash" do
    it "hashes the default transaction" do
      expect { tx.hash }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hash).to eq "23faa18497b6d4d790ff0798704975533d9f46ec08e73d6a5477b6703754da01"
    end

    it "hashes a known goerli transaction" do
      expect { legacy.hash }.to raise_error StandardError, "Transaction is not signed!"
      legacy.sign(testnet)
      expect(legacy.hash).to eq "1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1"
    end
  end

  describe ".copy" do
    it "can duplicate transactions" do
      raw = "f9010c80018252088080b8c000000000000000000000000000000000000000000000000000000000000000800000000000000000000000003ea1e26a2119b038eaf9b27e65cdb401502ae7a43d8bfb1368aee2693eb325af9f81244b19304b087b4941a1e892da50bd48dfe1f6d17aad7aff1c87e8481f30395a1595a07b483032affed044e698bf7c43a6fe000000000000000000000000000000000000000000000000000000000000000d4c6f72656d2c20497073756d210000000000000000000000000000000000000026a0e06be7a71c58beebfae09372083865f49fbacb6dfd93f10329f2ca925057fba3a0036c90afd27ea5d2383e319f7091aa23d3e77b09114d7e1d610d04dce8e8169f"
      legacy = Tx.decode raw
      duplicate = Tx.unsigned_copy legacy
      expect(legacy.signer_nonce).to eq duplicate.signer_nonce
      expect(legacy.gas_price).to eq duplicate.gas_price
      expect(legacy.gas_limit).to eq duplicate.gas_limit
      expect(legacy.destination).to eq duplicate.destination
      expect(legacy.amount).to eq duplicate.amount
      expect(legacy.payload).to eq duplicate.payload
      expect(legacy.chain_id).to eq duplicate.chain_id
      expect(legacy.type).to eq duplicate.type

      # unsigned
      expect(duplicate.signature_v).to eq legacy.chain_id
      expect(duplicate.signature_r).to eq 0
      expect(duplicate.signature_s).to eq 0

      # signed
      duplicate.sign cow
      expect(legacy.signature_v).to eq duplicate.signature_v
      expect(legacy.signature_r).to eq duplicate.signature_r
      expect(legacy.signature_s).to eq duplicate.signature_s
      expect(duplicate.hex).to eq raw
    end
  end

  context "signing transactions the hard way" do
    it "correctly hashes the unsigned python example" do

      # ref https://lsongnotes.wordpress.com/2018/01/14/signing-an-ethereum-transaction-the-hard-way/
      sample = Tx.new({
        nonce: 0,
        gas_price: 0x0BA43B7400,
        gas_limit: 0x05208,
        to: "0x7917bc33eea648809c285607579c9919fb864f8f",
        value: 0x03BAF82D03A000,
      })
      lsong = Key.new(priv: "00d862c318d05de0a1c25242c21989e15e35e70c55996fbc4238cd2f2f6a8f62")
      expected_address = Address.new "8d900bfa2353548a4631be870f99939575551b60"
      expected_sign_data = "EB80850BA43B7400825208947917bc33eea648809c285607579c9919fb864f8f8703BAF82D03A00080018080".downcase
      expected_sign_hash = "a4060d01d4add248db470b4121616cbe5b2015daf328809000ec9a1d0954d649"

      expect(lsong.address.to_s).to eq expected_address.to_s
      expect(Util.bin_to_hex sample.unsigned_encoded).to eq expected_sign_data
      expect(Util.bin_to_hex sample.unsigned_hash).to eq expected_sign_hash

      expected_raw = "F86B80850BA43B7400825208947917bc33eea648809c285607579c9919fb864f8f8703BAF82D03A0008025A0067940651530790861714b2e8fd8b080361d1ada048189000c07a66848afde46A069b041db7c29dbcc6becf42017ca7ac086b12bd53ec8ee494596f790fb6a0a69".downcase
      expect(Tx.decode(expected_raw).hex).to eq expected_raw
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
    subject(:expected_hex) { "f9010c80018259ac8080b8c000000000000000000000000000000000000000000000000000000000000000800000000000000000000000003ea1e26a2119b038eaf9b27e65cdb401502ae7a43d8bfb1368aee2693eb325af9f81244b19304b087b4941a1e892da50bd48dfe1f6d17aad7aff1c87e8481f30395a1595a07b483032affed044e698bf7c43a6fe000000000000000000000000000000000000000000000000000000000000000d4c6f72656d2c20497073756d210000000000000000000000000000000000000026a0b06ef4fc47e80f9fc70143b558dfa31d6dae04661f37715b982718f8185aefa3a032a8b187b43ae4af3755e7158f7cbb9585485e05ffdd38fe3343767a61730026" }
    subject(:expected_hash) { "3ac265b9741844e04f9ac8436469393a44d89d6fe20343fc9ea60f0f377db9ec" }

    it "can create transactions with binary data" do
      abi = Abi.encode types, args
      some = Tx.new({
        nonce: 0,
        gas_price: 1,
        gas_limit: 22_956,
        data: abi,
      })

      # expect to properly accept binary data
      some.sign cow
      expect(some.hex).to eq expected_hex
      expect(some.hash).to eq expected_hash

      # expect to match both decoded transaction and decoded abi
      other = Tx.decode some.hex
      expect(other.payload).to eq some.payload
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
        gas_limit: 22_956,
        data: hex,
      })

      # expect to properly accept hexadecimal data without changing the transaction hash
      some.sign cow
      expect(some.hex).to eq expected_hex
      expect(some.hash).to eq expected_hash

      # expect to match both decoded transaction and decoded abi
      other = Tx.decode some.hex
      expect(other.payload).to eq some.payload
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
        gas_limit: 21_208,
        data: lorem,
      })
      some.sign cow
      expect(some.hex).to eq "f85880018252d880808d4c6f72656d2c20497073756d2125a08540db1627dd415d4b53f2d0b7835510ab9cfc77ad40a785e7e0dc6ec63cef79a02822730ee77dfddee349d720e3cfa955b38f7ffb9e482e4c15931bb9cca0c33c"
      expect(some.hash).to eq "37aa7c93ffcbc92bcd016796ae231ea2ddce5c0daa5f5646784d3cbb9b6cff3b"

      # expect to match both decoded transaction and decoded abi
      other = Tx.decode some.hex
      expect(other.payload).to eq some.payload
      expect(other.hex).to eq some.hex
      expect(other.hash).to eq some.hash

      # same string
      expect(other.payload).to eq lorem
    end
  end
end
