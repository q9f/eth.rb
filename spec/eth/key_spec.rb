require 'spec_helper'

describe Eth::Key do
  describe ".initialize" do
    subject(:alice) { Eth::Key.new }
    subject(:bob) { Eth::Key.new }

    it "generates functional keypairs" do

      # generates a functional key for alice of type Eth::Key
      expect(alice).to be_an_instance_of Eth::Key

      # generates a functional key for bob of type Eth::Key
      expect(bob).to be_an_instance_of Eth::Key

      # ensure both keys are not the same
      expect(alice.private_key).not_to eq(bob.private_key)
      expect(alice.private_hex).not_to eq(bob.private_hex)
      expect(alice.private_bytes).not_to eq(bob.private_bytes)
      expect(alice.public_key).not_to eq(bob.public_key)
      expect(alice.public_hex).not_to eq(bob.public_hex)
      expect(alice.public_hex_compressed).not_to eq(bob.public_hex_compressed)
      expect(alice.public_bytes).not_to eq(bob.public_bytes)
      expect(alice.public_bytes_compressed).not_to eq(bob.public_bytes_compressed)
    end

    it "restores keypairs from existing private keys" do

      # creates a backup of alice's keypair
      backup = Eth::Key.new priv: alice.private_key.data

      # ensure both keys are the same
      expect(alice.private_key).to eq(backup.private_key)
      expect(alice.private_hex).to eq(backup.private_hex)
      expect(alice.private_bytes).to eq(backup.private_bytes)
      expect(alice.public_key).to eq(backup.public_key)
      expect(alice.public_hex).to eq(backup.public_hex)
      expect(alice.public_hex_compressed).to eq(backup.public_hex_compressed)
      expect(alice.public_bytes).to eq(backup.public_bytes)
      expect(alice.public_bytes_compressed).to eq(backup.public_bytes_compressed)
    end

    it "can handle hex and byte private keys" do
      alice = Eth::Key.new
      backup_from_bytes = Eth::Key.new priv: alice.private_bytes
      backup_from_hex = Eth::Key.new priv: alice.private_hex

      expect(alice.private_key).to eq(backup_from_bytes.private_key)
      expect(alice.private_key).to eq(backup_from_hex.private_key)
      expect(alice.private_hex).to eq(backup_from_bytes.private_hex)
      expect(alice.private_hex).to eq(backup_from_hex.private_hex)
      expect(alice.private_bytes).to eq(backup_from_bytes.private_bytes)
      expect(alice.private_bytes).to eq(backup_from_hex.private_bytes)
    end
  end

  describe ".private_key" do
    subject(:charlie) { Eth::Key.new }

    it "generates secp256k1 private keys" do

      # ensure private keys are sane
      expect(charlie.private_key).to be
      expect(charlie.private_key).to be_an_instance_of Secp256k1::PrivateKey
      expect(Eth::Utils.is_hex? charlie.private_hex).to be_truthy
      expect(Eth::Utils.is_hex? charlie.private_bytes).to be_falsy

      # check private keys are 32 bit
      expect(charlie.private_hex.size).to eq(64)
      expect(charlie.private_bytes.size).to eq(32)
    end
  end

  describe ".public_key" do
    subject(:dave) { Eth::Key.new }

    it "generates secp256k1 public keys" do

      # ensure public keys are sane
      expect(dave.public_key).to be
      expect(dave.public_key).to be_an_instance_of Secp256k1::PublicKey
      expect(Eth::Utils.is_hex? dave.public_hex).to be_truthy
      expect(Eth::Utils.is_hex? dave.public_hex_compressed).to be_truthy
      expect(Eth::Utils.is_hex? dave.public_bytes).to be_falsy
      expect(Eth::Utils.is_hex? dave.public_bytes_compressed).to be_falsy

      # check public key sizes and first indicator bytes
      expect(dave.public_hex.size).to eq(130)
      expect(dave.public_hex[0, 2]).to eq("04")
      expect(dave.public_hex_compressed.size).to eq(66)
      expect(dave.public_hex_compressed[0, 2]).to eq("02").or eq("03")
      expect(dave.public_bytes.size).to eq(65)
      expect(dave.public_bytes.bytes.first).to eq(4)
      expect(dave.public_bytes_compressed.size).to eq(33)
      expect(dave.public_bytes_compressed.bytes.first).to eq(2).or eq(3)
    end
  end

  describe ".address" do
    it "generates a checksummed address" do
      address = '0x759b427456623a33030bbC2195439C22A8a51d25'
      priv = 'c3a4349f6e57cfd2cbba275e3b3d15a2e4cf00c89e067f6e05bfee25208f9cbb'

      # @TODO
      # key = Eth::Key.new priv: priv
    end
  end
end
