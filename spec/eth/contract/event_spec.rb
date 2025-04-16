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

  describe "#decode_params" do
    let(:event) do
      described_class.new({
        "name" => "TokenMint",
        "inputs" => [
          { "indexed" => true, "name" => "collection", "type" => "address" },
          { "indexed" => true, "name" => "tokenId", "type" => "uint256" },
          { "indexed" => true, "name" => "ipfsHash", "type" => "bytes32" },
          { "indexed" => false, "name" => "to", "type" => "address" },
        ],
      })
    end

    let(:topics) do
      [
        # Event Signature
        "0x56cf26bc53ebe38f9e4d908b15e9c50ad826767b3ae8726088db3772f9f9b61f",
        # collection
        "0x0000000000000000000000005c9cbf795b4d113e0cb34c5eb60ca1f41670d2fb",
        # tokenId
        "0x3c9995b18871ee6c45703900fdc22b220944763432b726a2d37e95559b866506",
        # ipfsHash
        "0xa02633d596babc5141f89d9f5737410b7559353a4aa3328c2a67668193eaa209",
      ]
    end

    let(:data) do
      # to address
      "0x000000000000000000000000f0d00750656f12ab7550bf5039d74691f9e461f0"
    end

    it "correctly decodes the event parameters" do
      decoded = event.decode_params(
        topics,
        data,
      )

      expect(decoded["collection"]).to eq("0x5c9cbf795b4d113e0cb34c5eb60ca1f41670d2fb")
      expect(decoded["tokenId"]).to eq(
        27410131662392648286045511960347474962097127373970128911820026866366436238598,
      )
      expect(decoded["ipfsHash"]).to eq(
        ["a02633d596babc5141f89d9f5737410b7559353a4aa3328c2a67668193eaa209"].pack("H*"),
      )
      expect(decoded["to"]).to eq("0xf0d00750656f12ab7550bf5039d74691f9e461f0")
    end
  end
end
