require "spec_helper"

describe Contract::Abi do
  let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
  subject(:erc20_abi) { JSON.parse erc20_abi_file }

  context ".parse_abi" do
    it "can parse ERC-20 ABI file" do
      data = Eth::Contract::Abi.parse_abi(erc20_abi)

      expect(data.size).to eq 3
      expect(data[0]).to eq([])
      expect(data[1][0].class).to eq(Eth::Contract::Function)
      expect(data[1][0].function_string).to eq("allowance(address,address)")
      expect(data[1][0].signature).to eq("dd62ed3e")
      expect(data[2][0].class).to eq(Eth::Contract::Event)
      expect(data[2][0].event_string).to eq("Approval(address,address,uint256)")
      expect(data[2][0].signature).to eq("8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925")
    end
  end
end
