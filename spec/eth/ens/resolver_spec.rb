require "spec_helper"

describe Ens::Resolver do
  let(:geth_dev_http_path) { "http://127.0.0.1:8545" }
  let(:geth_dev_http) { Client.create geth_dev_http_path }
  let(:resolver) { Ens::Resolver.new(geth_dev_http) }

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
    end
  end

  describe "resolve" do
    it "invokes calls to chain" do
      pending("Requires interacting with a ENS contract")
      expect(resolver.resolve("fancy.eth")).to_not be_nil
    end
  end
end
