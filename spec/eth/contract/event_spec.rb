require "spec_helper"

describe Contract::Event do
  let(:path) { "spec/fixtures/contracts/test_contract.sol" }
  subject(:contract) { Eth::Contract.from_file(file: path) }

  context ".initialize" do
    it "succeed" do
      expect(contract.events[0].name).to eq("changed")
      expect(contract.events[0].signature).to eq("0d3a6aeecf5d29a90d2c145270bd1b2554069d03e76c09a660b27ccd165c2c42")
      expect(contract.events[0].event_string).to eq("changed()")
      expect(contract.events[1].name).to eq("killed")
      expect(contract.events[1].signature).to eq("1f3a0e41bf4d8306f04763663bf025d1824a391571ce3a07186a195f8c4cfd3c")
      expect(contract.events[1].event_string).to eq("killed()")
    end

    it "generates signature for event with tuple params" do
      event = Eth::Contract::Event.new({
        "anonymous" => false,
        "inputs" => [
          {
            "components" => [
              {
                "internalType" => "uint256",
                "name" => "topicId",
                "type" => "uint256",
              },
              {
                "internalType" => "uint256",
                "name" => "proposalId",
                "type" => "uint256",
              },
              {
                "internalType" => "string",
                "name" => "name",
                "type" => "string",
              },
              {
                "internalType" => "string",
                "name" => "symbol",
                "type" => "string",
              },
              {
                "internalType" => "uint256",
                "name" => "duration",
                "type" => "uint256",
              },
              {
                "internalType" => "uint256",
                "name" => "totalSupply",
                "type" => "uint256",
              },
              {
                "internalType" => "uint256",
                "name" => "miniStakeValue",
                "type" => "uint256",
              },
              {
                "internalType" => "uint256",
                "name" => "maxStakeValue",
                "type" => "uint256",
              },
              {
                "internalType" => "uint256",
                "name" => "maxParticipants",
                "type" => "uint256",
              },
              {
                "internalType" => "uint256",
                "name" => "whitelistIndex",
                "type" => "uint256",
              },
              {
                "internalType" => "address",
                "name" => "proposer",
                "type" => "address",
              },
              {
                "internalType" => "bool",
                "name" => "useWhitelist",
                "type" => "bool",
              },
            ],
            "indexed" => false,
            "internalType" => "struct VoteContract.ProposalCreatedParams",
            "name" => "params",
            "type" => "tuple",
          },
        ],
        "name" => "ProposalCreated",
        "type" => "event",
      })
      expect(event.event_string).to eq("ProposalCreated((uint256,uint256,string,string,uint256,uint256,uint256,uint256,uint256,uint256,address,bool))")
      expect(event.signature).to eq("4449031b77cbe261580701c097fb63211e768f685581e616330dfff20493536c")
    end
  end
end
