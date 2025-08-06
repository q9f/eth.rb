require "spec_helper"

describe Abi::Function do
  let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
  subject(:interfaces) { JSON.parse(erc20_abi_file).select { |i| i["type"] == "function" } }

  let(:functions) { interfaces.map { |fun| Eth::Contract::Function.new(fun) } }

  describe ".type" do
    it "encodes tuple types recursively" do
      input = {
        "type" => "tuple",
        "components" => [{ "type" => "address" }, { "type" => "uint256" }],
      }
      expect(Abi::Function.type(input)).to eq("(address,uint256)")
    end

    it "normalizes enum types" do
      input = { "type" => "enum" }
      expect(Abi::Function.type(input)).to eq("uint8")
    end
  end

  describe ".decode" do
    it "decodes function call data" do
      approve = functions.find { |f| f.name == "approve" }
      data = approve.encode_call("0x7f8c1877ed0da352f78be4fe4cda58bb804a30df", 1_000_000)

      call = Abi::Function.decode(interfaces, data)
      expect(call).not_to be_nil
      expect(call.name).to eq("approve")
      expect(call.args[0]).to eq("0x7f8c1877ed0da352f78be4fe4cda58bb804a30df")
      expect(call.args[1]).to eq(1_000_000)
      expect(call.kwargs[:spender]).to eq("0x7f8c1877ed0da352f78be4fe4cda58bb804a30df")
      expect(call.kwargs[:amount]).to eq(1_000_000)
      expect(call.signature).to eq("approve(address,uint256)")
    end
  end
end
