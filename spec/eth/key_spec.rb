require "spec_helper"

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
      expect(alice.private_key).not_to eq bob.private_key
      expect(alice.private_hex).not_to eq bob.private_hex
      expect(alice.private_bytes).not_to eq bob.private_bytes
      expect(alice.public_key).not_to eq bob.public_key
      expect(alice.public_hex).not_to eq bob.public_hex
      expect(alice.public_hex_compressed).not_to eq bob.public_hex_compressed
      expect(alice.public_bytes).not_to eq bob.public_bytes
      expect(alice.public_bytes_compressed).not_to eq bob.public_bytes_compressed
    end

    it "restores keypairs from existing private keys" do

      # creates a backup of alice's keypair
      backup = Eth::Key.new priv: alice.private_key.data

      # ensure both keys are the same
      expect(alice.private_key).to eq backup.private_key
      expect(alice.private_hex).to eq backup.private_hex
      expect(alice.private_bytes).to eq backup.private_bytes
      expect(alice.public_key).to eq backup.public_key
      expect(alice.public_hex).to eq backup.public_hex
      expect(alice.public_hex_compressed).to eq backup.public_hex_compressed
      expect(alice.public_bytes).to eq backup.public_bytes
      expect(alice.public_bytes_compressed).to eq backup.public_bytes_compressed
    end

    it "can handle hex and byte private keys" do
      alice = Eth::Key.new
      backup_from_bytes = Eth::Key.new priv: alice.private_bytes
      backup_from_hex = Eth::Key.new priv: alice.private_hex

      # it should be correct no matter what format we pass through
      expect(alice.private_key).to eq backup_from_bytes.private_key
      expect(alice.private_key).to eq backup_from_hex.private_key
      expect(alice.private_hex).to eq backup_from_bytes.private_hex
      expect(alice.private_hex).to eq backup_from_hex.private_hex
      expect(alice.private_bytes).to eq backup_from_bytes.private_bytes
      expect(alice.private_bytes).to eq backup_from_hex.private_bytes
    end
  end

  describe ".personal_sign" do
    subject(:eve) { Eth::Key.new }
    let(:message) { "Hi Mom!" }

    it "signs a message so that the public key can be recovered with personal_recover" do
      10.times do
        signature = eve.personal_sign message
        expect(Eth::Signature.personal_recover message, signature).to eq(eve.public_hex)
      end
    end

    it "also signs and recovers signatures with testnet chain IDs" do
      known_key = Eth::Key.new priv: "268be6f4a68c40f6862b7ac9aed8f701dc25a95ddb9a44d8b1f520b75f440a9a"
      chain = Eth::Chain::GOERLI
      expected_sig = "5d4bbc6e3ba797ab41821bd5ee33b3f30618ff71f1d41b6ebd8ac9731fda2b755269c3b0f332ff8473b21ae93bb03587ab181cca0674784894517a8e3b839c1e2d"
      signature = known_key.personal_sign message, chain
      expect(signature).to eq expected_sig
      recovered_key = Eth::Signature.personal_recover message, signature, chain
      expect(known_key.public_hex).to eq recovered_key
    end
  end

  describe ".private_key" do
    subject(:charlie) { Eth::Key.new }

    it "generates secp256k1 private keys" do

      # ensure private keys are sane
      expect(charlie.private_key).to be
      expect(charlie.private_key).to be_an_instance_of Secp256k1::PrivateKey
      expect(Eth::Util.is_hex? charlie.private_hex).to be_truthy
      expect(Eth::Util.is_hex? charlie.private_bytes).to be_falsy

      # check private keys are 32 bit
      expect(charlie.private_hex.size).to eq 64
      expect(charlie.private_bytes.size).to eq 32
    end
  end

  describe ".public_key" do
    subject(:dave) { Eth::Key.new }

    it "generates secp256k1 public keys" do

      # ensure public keys are sane
      expect(dave.public_key).to be
      expect(dave.public_key).to be_an_instance_of Secp256k1::PublicKey
      expect(Eth::Util.is_hex? dave.public_hex).to be_truthy
      expect(Eth::Util.is_hex? dave.public_hex_compressed).to be_truthy
      expect(Eth::Util.is_hex? dave.public_bytes).to be_falsy
      expect(Eth::Util.is_hex? dave.public_bytes_compressed).to be_falsy

      # check public key sizes and first indicator bytes
      expect(dave.public_hex.size).to eq 130
      expect(dave.public_hex[0, 2]).to eq "04"
      expect(dave.public_hex_compressed.size).to eq 66
      expect(dave.public_hex_compressed[0, 2]).to eq("02").or eq "03"
      expect(dave.public_bytes.size).to eq 65
      expect(dave.public_bytes.bytes.first).to eq 4
      expect(dave.public_bytes_compressed.size).to eq 33
      expect(dave.public_bytes_compressed.bytes.first).to eq(2).or eq 3
    end
  end

  describe ".address" do
    it "generates the correct address from key" do
      address = "0x759b427456623a33030bbC2195439C22A8a51d25"
      private_hex = "c3a4349f6e57cfd2cbba275e3b3d15a2e4cf00c89e067f6e05bfee25208f9cbb"
      key = Eth::Key.new priv: private_hex
      expect(key.address.checksummed).to eq address
    end
  end
end
