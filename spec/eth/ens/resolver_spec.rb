require "spec_helper"

describe Ens::Resolver do

  # it expects an $DRPC_TOKEN in environment
  let(:drpc_api) { "https://lb.drpc.org/ogrpc?network=ethereum&dkey=#{ENV["DRPC_TOKEN"]}" }
  subject(:drpc_mainnet) { Client.create drpc_api }
  let(:resolver) { Ens::Resolver.new(drpc_mainnet) }

  describe "normalize" do
    it "can normalize ascii" do
      expect(resolver.normalize("foo.eth")).to eq("foo.eth")
    end

    it "can normalize caps" do
      expect(resolver.normalize("Foo.eth")).to eq("foo.eth")
    end

    it "can not normalize illegal symbols" do
      expect {
        resolver.normalize("foo_bar.eth")
      }.to raise_error ArgumentError, "Provided ENS name contains illegal characters: foo_bar.eth"
    end

    it "can normalize emoji domains" do
      expect(resolver.normalize("🦚.eth")).to eq("🦚.eth")
    end
  end

  describe "namehash" do
    it "can generate correct name hashes" do
      expect(resolver.namehash("")).to eq("0x0000000000000000000000000000000000000000000000000000000000000000")
      expect(resolver.namehash("eth")).to eq("0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae")
      expect(resolver.namehash("foo.eth")).to eq("0xde9b09fd7c5f901e23a3f19fecc54828e9c848539801e86591bd9801b019f84f")
      expect(resolver.namehash("ncWc6Edqldzy6Mlo.eth")).to eq("0xfab68bf82e5750a73a16c3c157598b4be30ed6b7e048f8e29e11572119713eaa")
    end
  end
  describe "text" do
    it "gets text records for different keys" do
      expect(resolver.text("ncWc6Edqldzy6Mlo.eth")).to eq "ruby eth test account on mainnet"
      expect(resolver.text("ncWc6Edqldzy6Mlo.eth", "url")).to eq "https://github.com/q9f/eth.rb"
    end
  end
  describe "resolve" do
    it "gets resolver and owner from chain" do
      expect(resolver.owner("ncWc6Edqldzy6Mlo.eth")).to eq "0xe611a720778a5f6723d6b4866f84828504657181"
      expect(resolver.resolver("ncWc6Edqldzy6Mlo.eth").address).to eq "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41"
    end

    it "resolves ens names for Ethereum" do
      expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth")).to eq "0xde270e46d63b1816d1b798cff473c4ba238aca73"
    end

    it "resolves ens names for other coin types" do
      expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::ETHEREUM)).to eq "0xde270e46d63b1816d1b798cff473c4ba238aca73"
      expect {
        resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::BITCOIN)
      }.to raise_error NotImplementedError, "Coin type 0 not implemented!"
      expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::ETHEREUM_CLASSIC)).to eq "0x37287f68ac899b769faa57033c78b78c76c68dc0"
    end
  end
end
