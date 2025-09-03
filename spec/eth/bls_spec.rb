# frozen_string_literal: true

require "spec_helper"

RSpec.describe Eth::Bls do
  let(:priv_key) { "0x01" }
  let(:message) { "#{"ab" * 32}" }

  it "wraps signing and public key derivation" do
    pub_hex = Eth::Bls.get_public_key(priv_key)
    sig_hex = Eth::Bls.sign(message, priv_key)

    expect(pub_hex).to eq(Util.prefix_hex(BLS.get_public_key(0x01).to_hex(compressed: true)))
    expect(sig_hex).to eq(Util.prefix_hex(BLS.sign(message, 0x01).to_hex(compressed: true)))
  end

  it "encodes and decodes BLS public keys and signatures" do
    pub_hex = Eth::Bls.get_public_key(priv_key)
    sig_hex = Eth::Bls.sign(message, priv_key)

    decoded_pub = Eth::Bls.decode_public_key(pub_hex)
    decoded_sig = Eth::Bls.decode_signature(sig_hex)

    expect(Eth::Bls.encode_public_key(decoded_pub)).to eq(pub_hex)
    expect(Eth::Bls.encode_signature(decoded_sig)).to eq(sig_hex)
  end

  it "verifies signatures using precompile wrapper" do
    pub_hex = Eth::Bls.get_public_key(priv_key)
    sig_hex = Eth::Bls.sign(message, priv_key)

    expect(Eth::Bls.verify(message, sig_hex, pub_hex)).to be true
    expect(Eth::Bls.verify("deadbeef", sig_hex, pub_hex)).to be false
  end
end
