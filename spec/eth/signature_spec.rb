require 'spec_helper'

describe Eth::Signature do
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
      address = Eth::Address.new '0x4fCA53a6658648060e0a1Ca8427Abdd6063eDf6A'
      message = "Hello World!"
      signature = "0x21fbf0696d5e0aa2ef41a2b4ffb623bcaf070461d61cf7251c74161f82fec3a4370854bc0a34b3ab487c1bc021cd318c734c51ae29374f2beb0e6f2dd49b4bf41c"
      expect(Eth::Utils.public_key_to_address(Eth::Signature.personal_recover(message, signature)).to_s).to eq address.to_s
    end
  end
end
