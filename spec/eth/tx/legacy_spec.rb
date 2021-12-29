# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Eth::Tx::Legacy do
  subject(:tx) { Eth::Tx::Legacy.new(0, Eth::Unit::WEI, Eth::Tx::DEFAULT_LIMIT) }
  subject(:cow) { Eth::Key.new(priv: Eth::Util.keccak256("cow")) }

  # ref https://goerli.etherscan.io/tx/0x1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1
  subject(:legacy) { Eth::Tx::Legacy.new(1, 40 * Eth::Unit::GWEI, 21576, "0xcaa29806044a08e533963b2e573c1230a2cd9a2d", BigDecimal("0.123456789012345678") * Eth::Unit::ETHER, "Lorem Ipsum Ruby Ethereum Test 1-2-3") }
  subject(:testnet) { Eth::Key.new(priv: "0xc6c633f85d3f9a4705623b1d9bd1122a1a9196cd53dd352505e895fcbb8452ef") }

  describe ".decode" do
    it "decodes transactions" do
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
      expect(tx.signature_r).to eq "6b420feb4adbef529c2a8eb34c2691e400519cb2e8b3588b9f9c1fe7cb3c05b2"
      expect(tx.signature_s).to eq "567e4829aa10c7c3e538722768ca143f53d59cb0b1cb4a11605f767f885328d8"
    end

    it "signs a known goerli transaction" do
      expect { legacy.hash }.to raise_error StandardError, "Transaction is not signed!"
      expect(testnet.address.to_s).to eq "0x4762119a7249823D18aec7EAB73258B2D5061Dd8"

      # ue = legacy.unsigned_encoded
      # RLP.decode(ue)
      legacy.sign(testnet, Eth::Chain::GOERLI)
      # en = legacy.encoded
      # p RLP.decode(en)
      # expected = Eth::Util.hex_to_bin("f890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab")
      # p extx = RLP.decode(expected)

      # expect(legacy.signature_v).to eq "2e"
      # expect(legacy.signature_r).to eq "fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3a"
      # expect(legacy.signature_s).to eq "66c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
      # expect(legacy.hex).to eq "0xf890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
      # expect(legacy.hash).to eq "1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1"
    end
  end

  describe ".encoded" do
    it "encodes the default transaction" do
      expect { tx.encoded }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      # expect(tx.encoded).to eq "\xF8\x8F\x80\x01\x82R\b\x80\x80\x80\x8225\xB8@6b420feb4adbef529c2a8eb34c2691e400519cb2e8b3588b9f9c1fe7cb3c05b2\xB8@567e4829aa10c7c3e538722768ca143f53d59cb0b1cb4a11605f767f885328d8"
    end
  end

  describe ".hex" do
    it "hexes the default transaction" do
      expect { tx.hex }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      # expect(tx.hex).to eq "f88f8001825208808080823235b84036623432306665623461646265663532396332613865623334633236393165343030353139636232653862333538386239663963316665376362336330356232b84035363765343832396161313063376333653533383732323736386361313433663533643539636230623163623461313136303566373637663838353332386438"
      # expect(tx.raw).to eq "f88f8001825208808080823235b84036623432306665623461646265663532396332613865623334633236393165343030353139636232653862333538386239663963316665376362336330356232b84035363765343832396161313063376333653533383732323736386361313433663533643539636230623163623461313136303566373637663838353332386438"
    end

    it "hexes a known goerli transaction" do
      expect { legacy.hex }.to raise_error StandardError, "Transaction is not signed!"
      legacy.sign(testnet)
      # expect(legacy.hex).to eq "0xf890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
      # expect(legacy.raw).to eq "0xf890018509502f900082544894caa29806044a08e533963b2e573c1230a2cd9a2d8801b69b4ba630f34ea44c6f72656d20497073756d205275627920457468657265756d205465737420312d322d332ea0fb4d308f3d3f9770f2652ef40ea8369ab372e59bad814fb227fae1fdfdfa4d3aa066c8a2a2a2abcd391bac8639995a10f1546a873ef5b452bfe5fc367901d9f4ab"
    end
  end

  describe ".hash" do
    it "hashes the default transaction" do
      expect { tx.hash }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      # expect(tx.hash).to eq "4a84ea9ee7843655ebe4afc515733eb4e2bb09768265ccf5c533a29d7a7d6f2c"
    end

    it "hashes a known goerli transaction" do
      expect { legacy.hash }.to raise_error StandardError, "Transaction is not signed!"
      legacy.sign(testnet)
      # expect(legacy.hash).to eq "1975df4e715ce4af46c604e3fafb763a51cc133a42e43566779b4d5608bb4af1"
    end
  end
end
