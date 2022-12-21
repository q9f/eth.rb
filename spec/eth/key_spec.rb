require "spec_helper"

describe Key do
  describe ".initialize" do
    subject(:alice) { Key.new }
    subject(:bob) { Key.new }

    it "generates functional keypairs" do

      # generates a functional key for alice of type Key
      expect(alice).to be_an_instance_of Key

      # generates a functional key for bob of type Key
      expect(bob).to be_an_instance_of Key

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
      backup = Key.new priv: alice.private_key.data

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
      alice = Key.new
      backup_from_bytes = Key.new priv: alice.private_bytes
      backup_from_hex = Key.new priv: alice.private_hex

      # it should be correct no matter what format we pass through
      expect(alice.private_key).to eq backup_from_bytes.private_key
      expect(alice.private_key).to eq backup_from_hex.private_key
      expect(alice.private_hex).to eq backup_from_bytes.private_hex
      expect(alice.private_hex).to eq backup_from_hex.private_hex
      expect(alice.private_bytes).to eq backup_from_bytes.private_bytes
      expect(alice.private_bytes).to eq backup_from_hex.private_bytes
    end
  end

  describe ".sign" do
    subject(:heidi) { Key.new }
    let(:blob) { Util.keccak256 "Lorem, Ipsum!" }

    it "signs a blob so that the public key can be recovered with recover" do
      10.times do
        signature = heidi.sign blob
        expect(Signature.recover blob, signature).to eq(heidi.public_hex)
      end
    end

    it "also signs and recovers signatures with testnet chain IDs" do
      known_key = Key.new priv: "8e091dfb95a1b03cdd22890248c3f1b0f048186f2f3aa93257bc5271339eb306"
      chain = Chain::GOERLI
      expected_sig = "84a96dcf08f901a887cef46ecd8de8246012993b5b2a4a46ab3f8036fe57c53937106b3e04ec557e4614ebe87dc1678c3d49402009f4fd0a8d1b5e24a5577b392e"
      signature = known_key.sign blob, chain
      expect(signature).to eq expected_sig
      recovered_key = Signature.recover blob, signature, chain
      expect(known_key.public_hex).to eq recovered_key
    end
  end

  describe ".personal_sign" do
    subject(:eve) { Key.new }
    let(:message) { "Hi Mom!" }

    it "signs a message so that the public key can be recovered with personal_recover" do
      10.times do
        signature = eve.personal_sign message
        expect(Signature.personal_recover message, signature).to eq(eve.public_hex)
      end
    end

    it "also signs and recovers signatures with testnet chain IDs" do
      known_key = Key.new priv: "268be6f4a68c40f6862b7ac9aed8f701dc25a95ddb9a44d8b1f520b75f440a9a"
      chain = Chain::GOERLI
      expected_sig = "5d4bbc6e3ba797ab41821bd5ee33b3f30618ff71f1d41b6ebd8ac9731fda2b755269c3b0f332ff8473b21ae93bb03587ab181cca0674784894517a8e3b839c1e2d"
      signature = known_key.personal_sign message, chain
      expect(signature).to eq expected_sig
      recovered_key = Signature.personal_recover message, signature, chain
      expect(known_key.public_hex).to eq recovered_key
    end
  end

  describe ".sign_typed_data" do

    # The EIP-712 example data structure for Mail.
    subject(:mail_data) {
      {
        :types => {
          :EIP712Domain => [
            { :name => "name", :type => "string" },
            { :name => "version", :type => "string" },
            { :name => "chainId", :type => "uint256" },
            { :name => "verifyingContract", :type => "address" },
          ],
          :Person => [
            { :name => "name", :type => "string" },
            { :name => "wallet", :type => "address" },
          ],
          :Mail => [
            { :name => "from", :type => "Person" },
            { :name => "to", :type => "Person" },
            { :name => "contents", :type => "string" },
          ],
        },
        :primaryType => "Mail",
        :domain => {
          :name => "Ether Mail",
          :version => "1",
          :chainId => Chain::ETHEREUM,
          :verifyingContract => Address.new("0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC").checksummed,
        },
        :message => {
          :from => {
            :name => "Cow",
            :wallet => Address.new("0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826").checksummed,
          },
          :to => {
            :name => "Bob",
            :wallet => Address.new("0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB").checksummed,
          },
          :contents => "Hello, Bob!",
        },
      }
    }

    # ref https://github.com/ethereum/EIPs/blob/7f606a6e0e24bcf38d18e5a8cd9fbc71565f3257/assets/eip-712/Example.js#L126
    subject(:cow) { Key.new priv: Util.keccak256("cow") }

    it "passes EIP-712 mail example with private key of cow" do
      expect(cow.address.to_s).to eq mail_data[:message][:from][:wallet]
      expect(cow.sign_typed_data mail_data).to eq "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"
    end

    # The EIP-712 test from MetaMask.
    # ref https://github.com/MetaMask/eth-sig-util/blob/73ace3309bf4b97d901fb66cd61db15eede7afe9/src/sign-typed-data.test.ts#L6311
    subject(:test_data) {
      {
        :types => {
          :EIP712Domain => [],
          :Message => [
            { :name => "data", :type => "string" },
          ],
        },
        :primaryType => "Message",
        :domain => {},
        :message => {
          :data => "test",
        },
      }
    }

    # ref https://github.com/MetaMask/eth-sig-util/blob/73ace3309bf4b97d901fb66cd61db15eede7afe9/src/sign-typed-data.test.ts#L11
    subject(:grace) { Key.new priv: "4af1bceebf7f3634ec3cff8a2c38e51178d5d4ce585c52d6043e5e2cc3418bb0" }

    it "passes EIP-712 metamask test data with known private key" do
      expect(grace.sign_typed_data test_data).to eq "f6cda8eaf5137e8cc15d48d03a002b0512446e2a7acbc576c01cfbe40ad9345663ccda8884520d98dece9a8bfe38102851bdae7f69b3d8612b9808e6337801601b"
    end
  end

  describe ".private_key" do
    subject(:charlie) { Key.new }

    it "generates secp256k1 private keys" do

      # ensure private keys are sane
      expect(charlie.private_key).to be
      expect(charlie.private_key).to be_an_instance_of Secp256k1::PrivateKey
      expect(Util.hex? charlie.private_hex).to be_truthy
      expect(Util.hex? charlie.private_bytes).to be_falsy

      # check private keys are 32 bit
      expect(charlie.private_hex.size).to eq 64
      expect(charlie.private_bytes.size).to eq 32
    end
  end

  describe ".public_key" do
    subject(:dave) { Key.new }

    it "generates secp256k1 public keys" do

      # ensure public keys are sane
      expect(dave.public_key).to be
      expect(dave.public_key).to be_an_instance_of Secp256k1::PublicKey
      expect(Util.hex? dave.public_hex).to be_truthy
      expect(Util.hex? dave.public_hex_compressed).to be_truthy
      expect(Util.hex? dave.public_bytes).to be_falsy
      expect(Util.hex? dave.public_bytes_compressed).to be_falsy

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
      key = Key.new priv: private_hex
      expect(key.address.checksummed).to eq address
    end
  end
end
