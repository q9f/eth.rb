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

  # ref https://sepolia.etherscan.io/tx/0x7613b4de482fcff616e11907d16ddba1aa950a020ec58e99ab28ba0c5926ec53
  subject(:legacy) {
    Tx.new(
      {
        nonce: 1,
        gas_price: 40 * Unit::GWEI,
        gas_limit: 21580,
        to: "0xcaa29806044a08e533963b2e573c1230a2cd9a2d",
        value: BigDecimal("0.123456789012345678") * Unit::ETHER,
        data: "Lorem Ipsum Ruby Ethereum Test 1-2-3",
      },
      Chain::SEPOLIA
    )
  }

  # ref https://sepolia.etherscan.io/tx/0x01fa6584df6326dc503ca809c9c4643cd753ba8ae63473a9994770f403cda447
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
      Chain::SEPOLIA
    )
  }

  # ref https://sepolia.etherscan.io/address/0xc3c8fd0f04b629c5e2297b79c54dd57b85a721e3
  subject(:testnet) { Key.new(priv: "0xa0d1f18547caa1fb5c121c862d8ac66d9d6afe0afa79b291ca197e64fdccfd23") }

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

    it "decodes a known sepolia transaction signed by ruby eth gem" do

      # ref https://sepolia.etherscan.io/getRawTx?tx=0x01fa6584df6326dc503ca809c9c4643cd753ba8ae63473a9994770f403cda447
      expected_hex = "0xf884038509c76524008259d894caa29806044a08e533963b2e573c1230a2cd9a2d8718838370f3400095466f6f20426172205275627920457468657265756d8401546d72a0980cf5d1c20ed6a44a57b4ec70301da608247013be59be740e471579a16b9963a053a2e3b95f666c38ec26c0be6105affd23c037c67277ed920aae79f93c020fa6"
      expected_hash = "0x01fa6584df6326dc503ca809c9c4643cd753ba8ae63473a9994770f403cda447"
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
          chain_id: Chain::ETHEREUM,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 30000001!"
      expect {
        Tx.new({
          nonce: 0,
          gas_price: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT + 1,
          chain_id: Chain::OPTIMISM,
        })
      }.not_to raise_error # Block gas limit is only enforced in Ethereum mainnet
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
      expect(testnet.address.to_s).to eq "0xC3c8Fd0f04B629c5E2297b79c54DD57b85A721e3"
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
      expect(legacy.encoded).to eq "\xF8\x94\x01\x85\tP/\x90\x00\x82TL\x94\xCA\xA2\x98\x06\x04J\b\xE53\x96;.W<\x120\xA2\xCD\x9A-\x88\x01\xB6\x9BK\xA60\xF3N\xA4Lorem Ipsum Ruby Ethereum Test 1-2-3\x84\x01Tmr\xA0\x9Eh\x00\x9D\xBA<\x05MyVM\x82W\x86\xE9Z\xE7t\xF2\xE5\xB2\xF4\xD7_\xA5X\x88=\v#_\x82\xA02\xDCc\t\xDD\xD9)\xF5\xB1\xFC\xE3\xC9\xEC\x04\x13\aR\xF4\n}\xA2\xF2\x82\xE7x\b\xD6\x97\x93\xF6F\xEF"
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
      expect(legacy.hex).to eq "f894018509502f900082544c94caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d338401546d72a09e68009dba3c054d79564d825786e95ae774f2e5b2f4d75fa558883d0b235f82a032dc6309ddd929f5b1fce3c9ec04130752f40a7da2f282e77808d69793f646ef"
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
      expect(legacy.hash).to eq "7613b4de482fcff616e11907d16ddba1aa950a020ec58e99ab28ba0c5926ec53"
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
    subject(:expected_hex) { "f9010c80018259b88080b8c000000000000000000000000000000000000000000000000000000000000000800000000000000000000000003ea1e26a2119b038eaf9b27e65cdb401502ae7a43d8bfb1368aee2693eb325af9f81244b19304b087b4941a1e892da50bd48dfe1f6d17aad7aff1c87e8481f30395a1595a07b483032affed044e698bf7c43a6fe000000000000000000000000000000000000000000000000000000000000000d4c6f72656d2c20497073756d210000000000000000000000000000000000000026a081bf91ec0984c884c7d8afe094743d30c73e08c6d6c2da497dbb75193dd0cd07a059189d3f14ea3e0eccc6240e019f09d6b277e1525a0aa7e5bdca9e444f6f4630" }
    subject(:expected_hash) { "045ef9de4ed1aee2274be36a92db5293063bee674ec46ad94ad4d057250db536" }

    it "can create transactions with binary data" do
      abi = Abi.encode types, args
      some = Tx.new({
        nonce: 0,
        gas_price: 1,
        gas_limit: 22_968,
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
        gas_limit: 22_968,
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
        gas_limit: 21_210,
        data: lorem,
      })
      some.sign cow
      expect(some.hex).to eq "f85880018252da80808d4c6f72656d2c20497073756d2125a0121ceae143464734a25416294fd324e8a5a8578bbad84b7044a2f84b2ae0c0e8a00f72e5a58b1c40a9484026137e69a00746d613bd9445d767a7d7a305a2947e2d"
      expect(some.hash).to eq "43bbce3dc6bc845bfbf052df40bfbf20086eb6f983c5aacf9a964a0cc6b1c22a"

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
