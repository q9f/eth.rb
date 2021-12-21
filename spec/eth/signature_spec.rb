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
  end
end
