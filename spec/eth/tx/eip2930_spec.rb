require "spec_helper"

describe Eth::Tx::Eip2930 do
  subject(:list) {
    [
      [
        "0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae",
        [
          "0x0000000000000000000000000000000000000000000000000000000000000003",
          "0x0000000000000000000000000000000000000000000000000000000000000007",
        ],
      ],
      [
        "0xbb9bc244d798123fde783fcc1c72d3bb8c189413",
        [],
      ],
    ]
  }

  describe ".initialize" do
    it "creates EIP-2930 transaction payload objects" do
      expect(Eth::Tx::Eip2930.new({
        nonce: 0,
        gas_price: Eth::Unit::GWEI,
        gas_limit: Eth::Tx::DEFAULT_LIMIT,
      })).to be
      expect(Eth::Tx::Eip2930.new({
        nonce: 0,
        gas_price: Eth::Unit::GWEI,
        gas_limit: Eth::Tx::DEFAULT_LIMIT,
      })).to be_instance_of Eth::Tx::Eip2930
    end

    it "doesn't create invalid transaction payload objects" do
      expect {
        Eth::Tx::Eip2930.new({
          nonce: 0,
          gas_price: -9 * Eth::Unit::GWEI,
          gas_limit: Eth::Tx::DEFAULT_LIMIT,
        })
      }.to raise_error ArgumentError
      expect {
        Eth::Tx::Eip2930.new({
          nonce: 0,
          gas_price: Eth::Unit::GWEI,
          gas_limit: Eth::Tx::DEFAULT_LIMIT - 1,
        })
      }.to raise_error ArgumentError
      expect {
        Eth::Tx::Eip2930.new({
          nonce: 0,
          gas_price: Eth::Unit::GWEI,
          gas_limit: Eth::Tx::BLOCK_LIMIT + 1,
        })
      }.to raise_error ArgumentError
      expect {
        Eth::Tx::Eip2930.new({
          nonce: -1,
          gas_price: Eth::Unit::GWEI,
          gas_limit: Eth::Tx::BLOCK_LIMIT,
        })
      }.to raise_error ArgumentError
      expect {
        Eth::Tx::Eip2930.new({
          nonce: 0,
          gas_price: Eth::Unit::GWEI,
          gas_limit: Eth::Tx::BLOCK_LIMIT,
          to: "foo",
        })
      }.to raise_error ArgumentError
      expect {
        Eth::Tx::Eip2930.new({
          nonce: 0,
          gas_price: Eth::Unit::GWEI,
          gas_limit: Eth::Tx::BLOCK_LIMIT,
          to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
          value: -1,
        })
      }.to raise_error ArgumentError
      expect {
        Eth::Tx::Eip2930.new({
          nonce: 0,
          gas_price: Eth::Unit::GWEI,
          gas_limit: Eth::Tx::BLOCK_LIMIT,
          to: "0xef26b1f67797e7a5a3c192c93d821fadef3ba173",
          value: 1,
          access_list: "bar",
        })
      }.to raise_error ArgumentError
    end
  end

  context "signing transactions the hard way" do
    it "correctly hashes an unsigned example" do
      sample = Eth::Tx::Eip2930.new({
        nonce: 0,
        gas_price: 0x0BA43B7400,
        gas_limit: 0x05208,
        to: "0x7917bc33eea648809c285607579c9919fb864f8f",
        value: 0x03BAF82D03A000,
        access_list: list,
      })
      lsong = Eth::Key.new(priv: "00d862c318d05de0a1c25242c21989e15e35e70c55996fbc4238cd2f2f6a8f62")
      expected_address = Eth::Address.new "8d900bfa2353548a4631be870f99939575551b60"

      # a secp256k1 signature over keccak256(0x01 || rlp([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList]))
      expected_sign_data = "01f9010f0180850ba43b7400825208947917bc33eea648809c285607579c9919fb864f8f8703baf82d03a00080f8e4f8b5aa307864653062323935363639613966643933643566323864396563383565343066346362363937626165f888b842307830303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303033b842307830303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303037ecaa307862623962633234346437393831323366646537383366636331633732643362623863313839343133c0"
      expected_sign_hash = "d5f0a2ce85dc613ba965db24d17ceb73b6d6927eeaae8a56219968e0223eb45b"

      # first byte is type 01 as per EIP-2930
      expect(Eth::Util.bin_to_hex (sample.unsigned_encoded)[0, 1]).to eq "01"
      expect(Eth::Util.bin_to_hex sample.unsigned_encoded).to eq expected_sign_data
      expect(Eth::Util.bin_to_hex sample.unsigned_hash).to eq expected_sign_hash

      sample.sign lsong
      expect(Eth::Tx::Eip2930.decode(sample.hex).hex).to eq sample.hex
      expect(Eth::Tx::Eip2930.decode(sample.hex).hash).to eq sample.hash
    end
  end
end
