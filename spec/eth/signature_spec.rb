require "spec_helper"

describe Eth::Signature do
  describe ".prefix_message" do
    it "can properly prefix messages" do
      hello = "Hello World!"
      expect(Eth::Signature.prefix_message hello).to eq "\x19Ethereum Signed Message:\n12Hello World!"
      proof = "This is proof that I, user A, have access to this address."
      expect(Eth::Signature.prefix_message proof).to eq "\x19Ethereum Signed Message:\n58This is proof that I, user A, have access to this address."
    end
  end

  subject(:blob) { Eth::Util.keccak256 "Foo, Bar!" }

  describe ".recover" do
    it "can recover a public key from a signature of arbitrary data" do
      signature = "19fc60d0a0bd2d30838b3114c4066dcd980d7c909b215d2ce4a4539281588b7855ff925dbea288385056d811599983c8a65bafa31b6c1bcd2d6ae4bcc34377f526"
      public_hex = "0403a2a97e514ca6bac70d517761ba6db46cd52c6aa7f51d574de997aec914712a1312992d5bb85c2cf66063b62bc6c76c56a74438a4bd6f2a83977686b29e86ef"
      expect(Eth::Signature.recover blob, signature).to eq public_hex
    end

    it "raises argument errors if signature is invalid" do
      signature_invalid_v = "19fc60d0a0bd2d30838b3114c4066dcd980d7c909b215d2ce4a4539281588b7855ff925dbea288385056d811599983c8a65bafa31b6c1bcd2d6ae4bcc34377f5ff"
      signature_invalid_size = "19fc60d0a0bd2d30838b3114c4066dcd980d7c909b215d2ce4a4539281588b7855ff925dbea288385056d811599983c8a65bafa31b6c1bcd2d6ae4bcc34377f52600"
      expect { Eth::Signature.recover(blob, signature_invalid_v) }.to raise_error ArgumentError
      expect { Eth::Signature.recover(blob, signature_invalid_size) }.to raise_error ArgumentError
    end
  end

  describe ".personal_recover" do
    it "can recover a public key from a signature generated with metamask" do
      message = "test"
      signature = "3eb24bd327df8c2b614c3f652ec86efe13aa721daf203820241c44861a26d37f2bffc6e03e68fc4c3d8d967054c9cb230ed34339b12ef89d512b42ae5bf8c2ae1c"
      public_hex = "043e5b33f0080491e21f9f5f7566de59a08faabf53edbc3c32aaacc438552b25fdde531f8d1053ced090e9879cbf2b0d1c054e4b25941dab9254d2070f39418afc"
      expect(Eth::Signature.personal_recover(message, signature).to_s).to eq public_hex
    end

    it "can recover a public key from a signature generated with ledger" do
      message = "test"
      signature = "0x5c433983b23738940ce256c59d5bc6a3d5fd12c5bc9bdbf0ffdffb7be1a09d1815ca1db167c61a10945837f3fb4821086d6656b4fa6ede9c4d1aeaf07e2b0adf01"
      public_hex = "04e51ff5abc511f2fda0f893c10054123e92527b5e69e24cca538e74edbd604508259e1b265b54628bc8024fb791e459f67adb770b20962eb38fabe8b86f2aebaa"
      expect(Eth::Signature.personal_recover message, signature).to eq public_hex
    end

    it "can recover an address from a signature generated with mycrypto" do
      alice = Eth::Address.new "0x4fCA53a6658648060e0a1Ca8427Abdd6063eDf6A"
      message = "Hello World!"
      signature = "0x21fbf0696d5e0aa2ef41a2b4ffb623bcaf070461d61cf7251c74161f82fec3a4370854bc0a34b3ab487c1bc021cd318c734c51ae29374f2beb0e6f2dd49b4bf41c"
      expect(Eth::Util.public_key_to_address(Eth::Signature.personal_recover(message, signature)).to_s).to eq alice.to_s

      # ref: https://support.mycrypto.com/how-to/getting-started/how-to-sign-and-verify-messages-on-ethereum/
      bob = Eth::Address.new "0x2a3052ef570a031400BffD61438b2D19e0E8abef"
      message = "This is proof that I, user A, have access to this address."
      signature = "0x4e1ce8ea60bc6dfd4068a35462612495850cb645a1c9f475eb969bff21d0b0fb414112aaf13f01dd18a3527cb648cdd51b618ae49d4999112c33f86b7b26e9731b"
      expect(Eth::Util.public_key_to_address(Eth::Signature.personal_recover(message, signature)).to_s).to eq bob.to_s
    end

    it "raises argument errors if signature is invalid" do
      message = "This is proof that I, user A, have access to this address."
      signature_invalid_v = "0x4e1ce8ea60bc6dfd4068a35462612495850cb645a1c9f475eb969bff21d0b0fb414112aaf13f01dd18a3527cb648cdd51b618ae49d4999112c33f86b7b26e97300"
      signature_invalid_size = "0x4e1ce8ea60bc6dfd4068a35462612495850cb645a1c9f475eb969bff21d0b0fb414112aaf13f01dd18a3527cb648cdd51b618ae49d4999112c33f86b7b26e973"
      expect { Eth::Signature.personal_recover(message, signature_invalid_v) }.to raise_error ArgumentError
      expect { Eth::Signature.personal_recover(message, signature_invalid_size) }.to raise_error ArgumentError
    end
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
  subject(:ivan) { Eth::Key.new priv: "4af1bceebf7f3634ec3cff8a2c38e51178d5d4ce585c52d6043e5e2cc3418bb0" }

  describe ".recover_typed_data" do
    it "recovers EIP-712 metamask test data with known private key" do
      signature = "f6cda8eaf5137e8cc15d48d03a002b0512446e2a7acbc576c01cfbe40ad9345663ccda8884520d98dece9a8bfe38102851bdae7f69b3d8612b9808e63378016025"
      expect(Eth::Signature.recover_typed_data test_data, signature).to eq ivan.public_hex
    end

    it "raises argument errors if signature is invalid" do
      signature_invalid_v = "f6cda8eaf5137e8cc15d48d03a002b0512446e2a7acbc576c01cfbe40ad9345663ccda8884520d98dece9a8bfe38102851bdae7f69b3d8612b9808e63378016024"
      signature_invalid_size = "f6cda8eaf5137e8cc15d48d03a002b0512446e2a7acbc576c01cfbe40ad9345663ccda8884520d98dece9a8bfe38102851bdae7f69b3d8612b9808e6337801602"
      expect { Eth::Signature.recover_typed_data(test_data, signature_invalid_v) }.to raise_error ArgumentError
      expect { Eth::Signature.recover_typed_data(test_data, signature_invalid_size) }.to raise_error ArgumentError
    end
  end

  describe ".verify" do
    it "can verify a signature generated with metamask" do
      message = "test"
      signature = "3eb24bd327df8c2b614c3f652ec86efe13aa721daf203820241c44861a26d37f2bffc6e03e68fc4c3d8d967054c9cb230ed34339b12ef89d512b42ae5bf8c2ae1c"
      public_hex = "043e5b33f0080491e21f9f5f7566de59a08faabf53edbc3c32aaacc438552b25fdde531f8d1053ced090e9879cbf2b0d1c054e4b25941dab9254d2070f39418afc"
      expect(Eth::Signature.verify message, signature, public_hex).to be_truthy
    end

    it "can verify a signature generated with ledger" do
      message = "test"
      signature = "0x5c433983b23738940ce256c59d5bc6a3d5fd12c5bc9bdbf0ffdffb7be1a09d1815ca1db167c61a10945837f3fb4821086d6656b4fa6ede9c4d1aeaf07e2b0adf01"
      public_hex = "04e51ff5abc511f2fda0f893c10054123e92527b5e69e24cca538e74edbd604508259e1b265b54628bc8024fb791e459f67adb770b20962eb38fabe8b86f2aebaa"
      expect(Eth::Signature.verify message, signature, public_hex).to be_truthy
    end

    it "can verify a generated with mycrypto" do
      alice = Eth::Address.new "0x4fCA53a6658648060e0a1Ca8427Abdd6063eDf6A"
      message = "Hello World!"
      signature = "0x21fbf0696d5e0aa2ef41a2b4ffb623bcaf070461d61cf7251c74161f82fec3a4370854bc0a34b3ab487c1bc021cd318c734c51ae29374f2beb0e6f2dd49b4bf41c"
      expect(Eth::Signature.verify message, signature, alice).to be_truthy

      # ref: https://support.mycrypto.com/how-to/getting-started/how-to-sign-and-verify-messages-on-ethereum/
      bob = Eth::Address.new "0x2a3052ef570a031400BffD61438b2D19e0E8abef"
      message = "This is proof that I, user A, have access to this address."
      signature = "0x4e1ce8ea60bc6dfd4068a35462612495850cb645a1c9f475eb969bff21d0b0fb414112aaf13f01dd18a3527cb648cdd51b618ae49d4999112c33f86b7b26e9731b"
      expect(Eth::Signature.verify message, signature, bob).to be_truthy
    end

    it "can verify with any public key or address provided" do
      charlie = Eth::Key.new priv: "268be6f4a68c40f6862b7ac9aed8f701dc25a95ddb9a44d8b1f520b75f440a9a"
      message = "This is proof that I, user A, have access to this address."
      signature = "0x8fbb1df1a6ee4958e1ef900f2632cac95e0d0d62fa95d64a2ddae851f1124b7444776292a62208d729d0621dbe17533163db42a7b6bb13b2497cb73827760c4625"
      expect(Eth::Signature.verify message, signature, charlie.address).to be_truthy
      expect(Eth::Signature.verify message, signature, charlie.address.to_s).to be_truthy
      expect(Eth::Signature.verify message, signature, charlie.public_key).to be_truthy
      expect(Eth::Signature.verify message, signature, charlie.public_hex).to be_truthy
      expect { Eth::Signature.verify message, signature, charlie.private_hex }.to raise_error ArgumentError
    end

    it "verifies signed data no matter what format is given" do

      # personal message (String)
      alice = Eth::Address.new "0x4fCA53a6658648060e0a1Ca8427Abdd6063eDf6A"
      hello = "Hello World!"
      sig_alice = "0x21fbf0696d5e0aa2ef41a2b4ffb623bcaf070461d61cf7251c74161f82fec3a4370854bc0a34b3ab487c1bc021cd318c734c51ae29374f2beb0e6f2dd49b4bf41c"
      expect(Eth::Signature.verify hello, sig_alice, alice).to be_truthy

      # typed data (Array)
      sig_ivan = "f6cda8eaf5137e8cc15d48d03a002b0512446e2a7acbc576c01cfbe40ad9345663ccda8884520d98dece9a8bfe38102851bdae7f69b3d8612b9808e63378016025"
      expect(Eth::Signature.verify test_data, sig_ivan, ivan.public_hex).to be_truthy

      # binary data (ascii-8bit blob)
      sig_judy = "19fc60d0a0bd2d30838b3114c4066dcd980d7c909b215d2ce4a4539281588b7855ff925dbea288385056d811599983c8a65bafa31b6c1bcd2d6ae4bcc34377f526"
      pub_judy = "0403a2a97e514ca6bac70d517761ba6db46cd52c6aa7f51d574de997aec914712a1312992d5bb85c2cf66063b62bc6c76c56a74438a4bd6f2a83977686b29e86ef"
      expect(Eth::Signature.verify blob, sig_judy, pub_judy).to be_truthy
    end
  end
end
