require "spec_helper"

describe Ens::Resolver do

  # it expects an $INFURA_TOKEN in environment
  let(:infura_api) { "https://mainnet.infura.io/v3/#{ENV["INFURA_TOKEN"]}" }
  subject(:infura_mainnet) { Client.create infura_api }
  let(:resolver) { Ens::Resolver.new(infura_mainnet) }

  describe "normalize" do
    it "can normalize ascii" do
      expect(resolver.normalize("foo.eth")).to eq("foo.eth")
    end

    it "can normalize non-ascii (fold)" do
      pending("requires folding/advanced text processing")
      # with cyrillic 'o'
      expect(resolver.normalize("fоо.eth")).to eq("foo.eth")
    end

    it "can normalize caps" do
      expect(resolver.normalize("Foo.eth")).to eq("foo.eth")
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

  describe "resolve" do
    it "gets resolver and owner from chain" do
      expect(resolver.owner("ncWc6Edqldzy6Mlo.eth")).to eq "0xe611a720778a5f6723d6b4866f84828504657181"
      expect(resolver.resolver("ncWc6Edqldzy6Mlo.eth").address).to eq "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41"
    end

    it "resolves ens names for various coin types" do
      expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth")).to eq "0xde270e46d63b1816d1b798cff473c4ba238aca73"
      # expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::ETHEREUM)).to eq "0xde270e46d63b1816d1b798cff473c4ba238aca73"
      # expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::ETHEREUM_CLASSIC)).to eq "0x37287f68aC899b769FAa57033c78B78c76C68dc0"
      # expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::BITCOIN)).to eq "12bqzK1i8CqcNtBUkh4MQM9sPfjiG9UYRc"
      # expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::LITECOIN)).to eq "LVzCBuNmAnR7E5jPkoGo9bfm6BFtjDK1fd"
      # expect(resolver.resolve("ncWc6Edqldzy6Mlo.eth", Ens::CoinType::DOGECOIN)).to eq "DFVdh6xgP461P1G2CxVZ5D4XQogKbikcXF"
    end
  end
end
