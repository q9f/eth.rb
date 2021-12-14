require 'spec_helper'

describe Eth::Chains do
  describe "#CHAIN_ID" do
    it "has EIP155 chain ids for mainnets, testnets, and devnets" do
      # Chain IDs for selected mainnets
      expect(Eth::Chains::ETHEREUM).to eq 1
      expect(Eth::Chains::EXPANSE).to eq 2
      expect(Eth::Chains::OPTIMISM).to eq 10
      expect(Eth::Chains::CLASSIC).to eq 61
      expect(Eth::Chains::POA_NET).to eq 99
      expect(Eth::Chains::XDAI).to eq 100
      expect(Eth::Chains::ARBITRUM).to eq 42161

      # Chain IDs for selected testnets
      expect(Eth::Chains::MORDEN).to eq 2
      expect(Eth::Chains::ROPSTEN).to eq 3
      expect(Eth::Chains::RINKEBY).to eq 4
      expect(Eth::Chains::GOERLI).to eq 5
      expect(Eth::Chains::KOTTI).to eq 6
      expect(Eth::Chains::KOVAN).to eq 42
      expect(Eth::Chains::MORDEN_CLASSIC).to eq 62
      expect(Eth::Chains::MORDOR).to eq 63
      expect(Eth::Chains::KOVAN_OPTIMISM).to eq 69
      expect(Eth::Chains::XDAI_ARBITRUM).to eq 200
      expect(Eth::Chains::GOERLI_OPTIMISM).to eq 420
      expect(Eth::Chains::RINKEBY_ARBITRUM).to eq 421611

      # Chain IDs for selected private networks
      expect(Eth::Chains::PRIVATE_GETH).to eq 1337
    end
  end

  describe ".is_legacy" do
    it "can detect legacy values for v" do
      expect(Eth::Chains.is_legacy? 0).not_to be_truthy
      expect(Eth::Chains.is_legacy? 1).not_to be_truthy
      expect(Eth::Chains.is_legacy? 27).to be_truthy
      expect(Eth::Chains.is_legacy? 28).to be_truthy
      expect(Eth::Chains.is_legacy? 37).not_to be_truthy
      expect(Eth::Chains.is_legacy? 38).not_to be_truthy
    end
  end

  describe ".to_v .to_recovery_id" do
    it "can convert ethereum recovery ids to v" do
      expect(Eth::Chains.to_v 0).to be 37
      expect(Eth::Chains.to_v 1).to be 38
    end
    it "can convert other chain's recovery ids to v" do
      expect(Eth::Chains.to_v 0, Eth::Chains::CLASSIC).to be 157
      expect(Eth::Chains.to_v 1, Eth::Chains::XDAI).to be 236
      expect(Eth::Chains.to_v 0, Eth::Chains::ARBITRUM).to be 84357
      expect(Eth::Chains.to_v 1, Eth::Chains::MORDEN_CLASSIC).to be 160
      expect(Eth::Chains.to_v 0, Eth::Chains::GOERLI_OPTIMISM).to be 875
      expect(Eth::Chains.to_v 1, Eth::Chains::RINKEBY_ARBITRUM).to be 843258
      expect(Eth::Chains.to_v 0, Eth::Chains::PRIVATE_GETH).to be 2709
    end
    it "can recover v from ethereum recovery id" do
      expect(Eth::Chains.to_recov 37).to be 0
      expect(Eth::Chains.to_recov 38).to be 1
    end
    it "can recover v from other chain's recovery id" do
      expect(Eth::Chains.to_recov 157, Eth::Chains::CLASSIC).to be 0
      expect(Eth::Chains.to_recov 236, Eth::Chains::XDAI).to be 1
      expect(Eth::Chains.to_recov 84357, Eth::Chains::ARBITRUM).to be 0
      expect(Eth::Chains.to_recov 160, Eth::Chains::MORDEN_CLASSIC).to be 1
      expect(Eth::Chains.to_recov 875, Eth::Chains::GOERLI_OPTIMISM).to be 0
      expect(Eth::Chains.to_recov 843258, Eth::Chains::RINKEBY_ARBITRUM).to be 1
      expect(Eth::Chains.to_recov 2709, Eth::Chains::PRIVATE_GETH).to be 0
    end
    it "raises an error for invalid v on chain ids" do
      expect {Eth::Chains.to_recov 0}.to raise_error ArgumentError
      expect {Eth::Chains.to_recov 36}.to raise_error ArgumentError
      expect {Eth::Chains.to_recov 843258, Eth::Chains::PRIVATE_GETH}.to raise_error ArgumentError
    end
  end
end
