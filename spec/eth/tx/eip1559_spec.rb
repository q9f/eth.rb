# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Tx::Eip1559 do

  # ref https://goerli.etherscan.io/tx/0x737b57a273ea1e63e6b8f770313fc2fbc4a668706d2921292dd28307b9f9644f#accesslist
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

  # ref https://goerli.etherscan.io/tx/0x737b57a273ea1e63e6b8f770313fc2fbc4a668706d2921292dd28307b9f9644f
  subject(:type02) {
    Tx.new({
      chain_id: Chain::GOERLI,
      nonce: 5,
      priority_fee: 3 * Unit::GWEI,
      max_gas_fee: 69 * Unit::GWEI,
      gas_limit: 230_420,
      to: "0xCaA29806044A08E533963b2e573C1230A2cd9a2d",
      value: 0.069423 * Unit::ETHER,
      data: "Foo Bar Ruby Ethereum",
      access_list: list,
    })
  }

  # ref https://goerli.etherscan.io/getRawTx?tx=0x737b57a273ea1e63e6b8f770313fc2fbc4a668706d2921292dd28307b9f9644f
  subject(:type02_hex) { "0x02f8fb050584b2d05e00851010b872008303841494caa29806044a08e533963b2e573c1230a2cd9a2d87f6a3d9c63df00095466f6f20426172205275627920457468657265756df872f85994de0b295669a9fd93d5f28d9ec85e40f4cb697baef842a00000000000000000000000000000000000000000000000000000000000000003a00000000000000000000000000000000000000000000000000000000000000007d694bb9bc244d798123fde783fcc1c72d3bb8c189413c080a0d62447a61cde0aa0ed14d5826c8f4edf35c00c6583bbdd7366437b3de7fb0fd3a03b7dc632ef5df4e98c4b9546eb0c97e672798e8fda9aa70da0d585e0b7a30ae6" }

  # ref https://goerli.etherscan.io/tx/0x737b57a273ea1e63e6b8f770313fc2fbc4a668706d2921292dd28307b9f9644f
  subject(:type02_hash) { "0x737b57a273ea1e63e6b8f770313fc2fbc4a668706d2921292dd28307b9f9644f" }

  # ref https://goerli.etherscan.io/address/0x4762119a7249823d18aec7eab73258b2d5061dd8
  subject(:testnet) { Key.new(priv: "0xc6c633f85d3f9a4705623b1d9bd1122a1a9196cd53dd352505e895fcbb8452ef") }

  subject(:tx) {
    Tx.new({
      nonce: 0,
      priority_fee: 0,
      max_gas_fee: Unit::WEI,
      gas_limit: Tx::DEFAULT_GAS_LIMIT,
    })
  }

  subject(:cow) { Key.new(priv: Util.keccak256("cow")) }

  describe ".initialize" do
    it "creates EIP-1559 transaction objects" do
      expect(tx).to be
      expect(tx).to be_instance_of Tx::Eip1559
    end

    it "doesn't create invalid transaction objects" do
      expect {
        Tx.new({
          nonce: 0,
          priority_fee: -9,
          max_gas_fee: Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas priority fee -9!"
      expect {
        Tx.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: -9 * Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
        })
      }.to raise_error Tx::ParameterError, "Invalid max gas fee -0.9e10!"
      expect {
        Tx.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT - 1,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 20999!"
      expect {
        Tx.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::GWEI,
          gas_limit: Tx::DEFAULT_GAS_LIMIT,
          access_list: list,
        })
      }.to raise_error Tx::ParameterError, "Transaction gas limit is too low, try 29600!"
      expect {
        Tx.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT + 1,
          chain_id: Chain::ETHEREUM,
        })
      }.to raise_error Tx::ParameterError, "Invalid gas limit 30000001!"
      expect {
        Tx.new({
          nonce: -1,
          priority_fee: 0,
          max_gas_fee: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT,
        })
      }.to raise_error Tx::ParameterError, "Invalid signer nonce -1!"
      expect {
        Tx.new({
          nonce: 0,
          priority_fee: 0,
          max_gas_fee: Unit::GWEI,
          gas_limit: Tx::BLOCK_GAS_LIMIT,
          to: "foo",
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
        })
      }.to raise_error Tx::ParameterError, "Invalid access list bar!"
    end
  end

  describe ".sign" do
    it "signs the default transaction" do
      tx.sign(cow)
      expect(tx.signature_y_parity).to eq 1
      expect(tx.signature_r).to eq "2a64d34c75994de862676e452529802c1db357d3a73bfec132d5791214dae54e"
      expect(tx.signature_s).to eq "698374f7b0a76c22fde10bd90f96ec033632eadf7b8210a6a324bbee0a1a63f8"
    end

    it "it does not sign a transaction twice" do
      expect { type02.hash }.to raise_error StandardError, "Transaction is not signed!"
      expect(testnet.address.to_s).to eq "0x4762119a7249823D18aec7EAB73258B2D5061Dd8"
      type02.sign(testnet)
      expect { type02.sign(testnet) }.to raise_error StandardError, "Transaction is already signed!"
    end

    it "checks for valid sender" do
      tx_from_cow = Tx.new({
        nonce: 0,
        priority_fee: Unit::WEI,
        max_gas_fee: Unit::WEI,
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
      expect(tx.encoded).to eq "\x02\xF8N\x01\x80\x80\x01\x82R\b\x80\x80\x80\xC0\x01\xA0*d\xD3Lu\x99M\xE8bgnE%)\x80,\x1D\xB3W\xD3\xA7;\xFE\xC12\xD5y\x12\x14\xDA\xE5N\xA0i\x83t\xF7\xB0\xA7l\"\xFD\xE1\v\xD9\x0F\x96\xEC\x0362\xEA\xDF{\x82\x10\xA6\xA3$\xBB\xEE\n\x1Ac\xF8"
    end

    it "encodes a known goerli transaction" do
      expect { type02.encoded }.to raise_error StandardError, "Transaction is not signed!"
      type02.sign(testnet)
      expect(type02.encoded).to eq "\x02\xF8\xFB\x05\x05\x84\xB2\xD0^\x00\x85\x10\x10\xB8r\x00\x83\x03\x84\x14\x94\xCA\xA2\x98\x06\x04J\b\xE53\x96;.W<\x120\xA2\xCD\x9A-\x87\xF6\xA3\xD9\xC6=\xF0\x00\x95Foo Bar Ruby Ethereum\xF8r\xF8Y\x94\xDE\v)Vi\xA9\xFD\x93\xD5\xF2\x8D\x9E\xC8^@\xF4\xCBi{\xAE\xF8B\xA0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\xA0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\a\xD6\x94\xBB\x9B\xC2D\xD7\x98\x12?\xDEx?\xCC\x1Cr\xD3\xBB\x8C\x18\x94\x13\xC0\x80\xA0\xD6$G\xA6\x1C\xDE\n\xA0\xED\x14\xD5\x82l\x8FN\xDF5\xC0\fe\x83\xBB\xDDsfC{=\xE7\xFB\x0F\xD3\xA0;}\xC62\xEF]\xF4\xE9\x8CK\x95F\xEB\f\x97\xE6ry\x8E\x8F\xDA\x9A\xA7\r\xA0\xD5\x85\xE0\xB7\xA3\n\xE6"
    end
  end

  describe ".hex" do
    it "hexes the default transaction" do
      expect { tx.hex }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hex).to eq "02f84e01808001825208808080c001a02a64d34c75994de862676e452529802c1db357d3a73bfec132d5791214dae54ea0698374f7b0a76c22fde10bd90f96ec033632eadf7b8210a6a324bbee0a1a63f8"
    end

    it "hexes a known goerli transaction" do
      expect { type02.hex }.to raise_error StandardError, "Transaction is not signed!"
      type02.sign(testnet)
      expect(type02.hex).to eq Util.remove_hex_prefix type02_hex
    end
  end

  describe ".hash" do
    it "hashes the default transaction" do
      expect { tx.hash }.to raise_error StandardError, "Transaction is not signed!"
      tx.sign(cow)
      expect(tx.hash).to eq "46e942933749d1b58b006bb9f960b6e5e12decfb414d6c06e38b973179aa9116"
    end

    it "hashes a known goerli transaction" do
      expect { type02.hash }.to raise_error StandardError, "Transaction is not signed!"
      type02.sign(testnet)
      expect(type02.hash).to eq Util.remove_hex_prefix type02_hash
    end
  end

  describe ".copy" do
    it "can duplicate transactions" do
      eip1559 = Tx.decode type02_hex
      duplicate = Tx.unsigned_copy eip1559
      expect(eip1559.chain_id).to eq duplicate.chain_id
      expect(eip1559.signer_nonce).to eq duplicate.signer_nonce
      expect(eip1559.max_priority_fee_per_gas).to eq duplicate.max_priority_fee_per_gas
      expect(eip1559.max_fee_per_gas).to eq duplicate.max_fee_per_gas
      expect(eip1559.gas_limit).to eq duplicate.gas_limit
      expect(eip1559.destination).to eq duplicate.destination
      expect(eip1559.amount).to eq duplicate.amount
      expect(eip1559.payload).to eq duplicate.payload
      expect(eip1559.access_list).to eq duplicate.access_list
      expect(eip1559.type).to eq duplicate.type

      # unsigned
      expect(duplicate.signature_y_parity).not_to be
      expect(duplicate.signature_r).to eq 0
      expect(duplicate.signature_s).to eq 0

      # signed
      duplicate.sign testnet
      expect(eip1559.signature_y_parity).to eq duplicate.signature_y_parity
      expect(eip1559.signature_r).to eq duplicate.signature_r
      expect(eip1559.signature_s).to eq duplicate.signature_s
      expect(duplicate.hex).to eq Util.remove_hex_prefix type02_hex
    end
  end
end
