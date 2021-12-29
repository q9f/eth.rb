# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Eth::Tx::Legacy do
  subject(:tx) { Eth::Tx::Legacy.new(0, Eth::Unit::WEI, Eth::Tx::DEFAULT_LIMIT) }
  subject(:cow) { Eth::Key.new(priv: Eth::Util.keccak256("cow")) }

  # ref https://goerli.etherscan.io/tx/0x1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1
  subject(:legacy) { Eth::Tx::Legacy.new(1, 40 * Eth::Unit::GWEI, 21576, "0xcaa29806044a08e533963b2e573c1230a2cd9a2d", BigDecimal("0.123456789012345678") * Eth::Unit::ETHER, "Lorem Ipsum Ruby Ethereum Test 1-2-3", Eth::Chain::GOERLI) }
  subject(:testnet) { Eth::Key.new(priv: "0xc6c633f85d3f9a4705623b1d9bd1122a1a9196cd53dd352505e895fcbb8452ef") }

  describe ".decode" do
    it "decodes the first mainnet transaction" do

      # ref https://etherscan.io/tx/0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060
      expected_hex = "f86780862d79883d2000825208945df9b87991262f6ba471f09758cde1c0fc1de734827a69801ca088ff6cf0fefd94db46111149ae4bfc179e9b94721fffd821d38d16464b3f71d0a045e0aff800961cfce805daef7016b9b675c137a6a41a548f7b60a3484c06a33a"
      expected_hash = "5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060"
      tx = Eth::Tx::Legacy.decode(expected_hex)
      expect(tx.hex).to eq expected_hex
      expect(tx.hash).to eq expected_hash
    end

    it "decodes a low-gas mainnet transaction" do

      # ref https://etherscan.io/tx/0x1de3026bb6be99d36d2d263fdfa33c92705ec3a69b4a3577b9983168a6653d9c
      expected_hex = "f869018504a817c8008301daa094fe4fa55500bf397ef429021455c6a95f65a01b3c808441c0e1b51ba034d0434d6f032d982ad4e3b4ae79cd6455f1d13dd3b257b9c2ed3a95e48753c1a036e04c480078005be9c94a2eb4afbb36e8605ce80d809413355769cedf694be2"
      expected_hash = "1de3026bb6be99d36d2d263fdfa33c92705ec3a69b4a3577b9983168a6653d9c"
      tx = Eth::Tx::Legacy.decode(expected_hex)
      expect(tx.hex).to eq expected_hex
      expect(tx.hash).to eq expected_hash
    end

    it "decodes a known goerli transaction" do

      # ref https://goerli.etherscan.io/tx/0x1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1
      expected_hex = "f890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
      expected_hash = "1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1"
      tx = Eth::Tx::Legacy.decode(expected_hex)
      expect(tx.hex).to eq expected_hex
      expect(tx.hash).to eq expected_hash
    end
  end

  describe ".initialize" do
    it "creates legacy transaction objects" do
      expect(Eth::Tx::Legacy.new(0, Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT)).to be
      expect(Eth::Tx::Legacy.new(0, Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT)).to be_instance_of Eth::Tx::Legacy
    end

    it "doesn't create invalid transaction objects" do
      expect { Eth::Tx::Legacy.new(0, -9 * Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT) }.to raise_error ArgumentError
      expect { Eth::Tx::Legacy.new(0, Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT - 1) }.to raise_error ArgumentError
      expect { Eth::Tx::Legacy.new(0, Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT + 1) }.to raise_error ArgumentError
      expect { Eth::Tx::Legacy.new(-1, Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT) }.to raise_error ArgumentError
      expect { Eth::Tx::Legacy.new(0, Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT, "foo") }.to raise_error ArgumentError
      expect { Eth::Tx::Legacy.new(0, Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT, "0xef26b1f67797e7a5a3c192c93d821fadef3ba173", -1) }.to raise_error ArgumentError
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

  context "signing transactions the hard way" do
    it "correctly hashes the unsigned python example" do

      # ref https://lsongnotes.wordpress.com/2018/01/14/signing-an-ethereum-transaction-the-hard-way/
      sample = Eth::Tx::Legacy.new(0, 0x0BA43B7400, 0x05208, "0x7917bc33eea648809c285607579c9919fb864f8f", 0x03BAF82D03A000, "", 1)
      lsong = Eth::Key.new(priv: "00d862c318d05de0a1c25242c21989e15e35e70c55996fbc4238cd2f2f6a8f62")
      expected_address = Eth::Address.new "8d900bfa2353548a4631be870f99939575551b60"
      expected_sign_data = "EB80850BA43B7400825208947917bc33eea648809c285607579c9919fb864f8f8703BAF82D03A00080018080".downcase
      expected_sign_hash = "a4060d01d4add248db470b4121616cbe5b2015daf328809000ec9a1d0954d649"

      expect(lsong.address.to_s).to eq expected_address.to_s
      expect(Eth::Util.bin_to_hex sample.unsigned_encoded).to eq expected_sign_data
      expect(Eth::Util.bin_to_hex sample.unsigned_hash).to eq expected_sign_hash

      expected_raw = "F86B80850BA43B7400825208947917bc33eea648809c285607579c9919fb864f8f8703BAF82D03A0008025A0067940651530790861714b2e8fd8b080361d1ada048189000c07a66848afde46A069b041db7c29dbcc6becf42017ca7ac086b12bd53ec8ee494596f790fb6a0a69".downcase
      expect(Eth::Tx::Legacy.decode(expected_raw).hex).to eq expected_raw
    end
  end
end
