require "spec_helper"

describe Chain do
  context "#CHAIN_ID" do
    it "has EIP155 chain ids for mainnets, testnets, and devnets" do
      # Chain IDs for selected mainnets
      expect(Chain::ETHEREUM).to eq 1
      expect(Chain::EXPANSE).to eq 2
      expect(Chain::OPTIMISM).to eq 10
      expect(Chain::CLASSIC).to eq 61
      expect(Chain::CRONOS).to eq 25
      expect(Chain::RSK).to eq 30
      expect(Chain::BNB).to eq 56
      expect(Chain::POA_NET).to eq 99
      expect(Chain::XDAI).to eq 100
      expect(Chain::GNOSIS).to eq 100
      expect(Chain::MATIC).to eq 137
      expect(Chain::POLYGON).to eq 137
      expect(Chain::FILECOIN).to eq 314
      expect(Chain::CRONOS_ZK).to eq 388
      expect(Chain::REDSTONE).to eq 690
      expect(Chain::POLYGON_ZK).to eq 1101
      expect(Chain::LISK).to eq 1135
      expect(Chain::MOONBEAM).to eq 1284
      expect(Chain::BASE).to eq 8453
      expect(Chain::EVMOS).to eq 9001
      expect(Chain::CELO).to eq 42220
      expect(Chain::ARBITRUM).to eq 42161
      expect(Chain::AVALANCHE).to eq 43114
      expect(Chain::LINEA).to eq 59144
      expect(Chain::SCROLL).to eq 534352

      # Chain IDs for selected testnets
      expect(Chain::MORDEN).to eq 2
      expect(Chain::ROPSTEN).to eq 3
      expect(Chain::RINKEBY).to eq 4
      expect(Chain::GOERLI).to eq 5
      expect(Chain::KOTTI).to eq 6
      expect(Chain::KOVAN).to eq 42
      expect(Chain::MORDEN_CLASSIC).to eq 62
      expect(Chain::MORDOR).to eq 63
      expect(Chain::KOVAN_OPTIMISM).to eq 69
      expect(Chain::XDAI_ARBITRUM).to eq 200
      expect(Chain::GOERLI_OPTIMISM).to eq 420
      expect(Chain::MOONRIVER).to eq 1285
      expect(Chain::MOONBASE).to eq 1287
      expect(Chain::GARNET).to eq 17069
      expect(Chain::MUMBAI).to eq 80001
      expect(Chain::RINKEBY_ARBITRUM).to eq 421611
      expect(Chain::GOERLI_ARBITRUM).to eq 421613
      expect(Chain::SEPOLIA).to eq 11155111
      expect(Chain::HOLESOVICE).to eq 11166111
      expect(Chain::HOLESKY).to eq 11166111

      # Chain IDs for selected private networks
      expect(Chain::PRIVATE_GETH).to eq 1337
    end
  end

  describe ".ledger" do
    it "can detect ledger values for v" do
      expect(Chain.ledger? 0).to be_truthy
      expect(Chain.ledger? 1).to be_truthy
      expect(Chain.ledger? 27).not_to be_truthy
      expect(Chain.ledger? 28).not_to be_truthy
      expect(Chain.ledger? 37).not_to be_truthy
      expect(Chain.ledger? 38).not_to be_truthy
    end
  end

  describe ".legacy" do
    it "can detect legacy values for v" do
      expect(Chain.legacy? 0).not_to be_truthy
      expect(Chain.legacy? 1).not_to be_truthy
      expect(Chain.legacy? 27).to be_truthy
      expect(Chain.legacy? 28).to be_truthy
      expect(Chain.legacy? 37).not_to be_truthy
      expect(Chain.legacy? 38).not_to be_truthy
    end
  end

  describe ".to_v .to_recovery_id .to_chain_id" do
    it "can convert ethereum recovery ids to v" do
      expect(Chain.to_v 0).to eq 27
      expect(Chain.to_v 1).to eq 28
      expect(Chain.to_v 0, Chain::ETHEREUM).to eq 37
      expect(Chain.to_v 1, Chain::ETHEREUM).to eq 38
    end

    it "can convert other chain's recovery ids to v" do
      expect(Chain.to_v 0, Chain::CLASSIC).to eq 157
      expect(Chain.to_v 1, Chain::XDAI).to eq 236
      expect(Chain.to_v 0, Chain::ARBITRUM).to eq 84357
      expect(Chain.to_v 1, Chain::MORDEN_CLASSIC).to eq 160
      expect(Chain.to_v 0, Chain::GOERLI_OPTIMISM).to eq 875
      expect(Chain.to_v 1, Chain::RINKEBY_ARBITRUM).to eq 843258
      expect(Chain.to_v 0, Chain::PRIVATE_GETH).to eq 2709
    end

    it "can recover v from ethereum recovery id" do
      expect(Chain.to_recovery_id 37).to eq 0
      expect(Chain.to_recovery_id 38).to eq 1

      # legacy v
      expect(Chain.to_recovery_id 0).to eq 0
      expect(Chain.to_recovery_id 1).to eq 1
      expect(Chain.to_recovery_id 27).to eq 0
      expect(Chain.to_recovery_id 28).to eq 1
    end

    it "can recover v from other chain's recovery id" do
      expect(Chain.to_recovery_id 157, Chain::CLASSIC).to eq 0
      expect(Chain.to_recovery_id 236, Chain::XDAI).to eq 1
      expect(Chain.to_recovery_id 84357, Chain::ARBITRUM).to eq 0
      expect(Chain.to_recovery_id 160, Chain::MORDEN_CLASSIC).to eq 1
      expect(Chain.to_recovery_id 875, Chain::GOERLI_OPTIMISM).to eq 0
      expect(Chain.to_recovery_id 843258, Chain::RINKEBY_ARBITRUM).to eq 1
      expect(Chain.to_recovery_id 2709, Chain::PRIVATE_GETH).to eq 0
    end

    it "raises an error for invalid v on chain ids" do
      expect { Chain.to_recovery_id -1 }.to raise_error Chain::ReplayProtectionError, "Invalid v -1 value for chain ID 1. Invalid chain ID?"
      expect { Chain.to_recovery_id 36 }.to raise_error Chain::ReplayProtectionError, "Invalid v 36 value for chain ID 1. Invalid chain ID?"
      expect { Chain.to_recovery_id 843258, Chain::PRIVATE_GETH }.to raise_error Chain::ReplayProtectionError, "Invalid v 843258 value for chain ID 1337. Invalid chain ID?"
    end

    it "can recover chain ids from v" do
      expect(Chain.to_chain_id 37).to eq Chain::ETHEREUM
      expect(Chain.to_chain_id 38).to eq Chain::ETHEREUM
      expect(Chain.to_chain_id 157).to eq Chain::CLASSIC
      expect(Chain.to_chain_id 236).to eq Chain::XDAI
      expect(Chain.to_chain_id 84357).to eq Chain::ARBITRUM
      expect(Chain.to_chain_id 160).to eq Chain::MORDEN_CLASSIC
      expect(Chain.to_chain_id 875).to eq Chain::GOERLI_OPTIMISM
      expect(Chain.to_chain_id 843258).to eq Chain::RINKEBY_ARBITRUM
      expect(Chain.to_chain_id 2709).to eq Chain::PRIVATE_GETH

      # legacy v
      expect(Chain.to_chain_id 0).not_to be
      expect(Chain.to_chain_id 1).not_to be
      expect(Chain.to_chain_id 27).not_to be
      expect(Chain.to_chain_id 28).not_to be
    end
  end
end
