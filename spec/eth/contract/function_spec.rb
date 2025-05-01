require "spec_helper"

describe Contract::Function do
  let(:erc20_abi_file) { File.read "spec/fixtures/abi/ERC20.json" }
  let(:abi) { JSON.parse erc20_abi_file }
  subject(:functions) { abi.select { |x| x["type"] == "function" }.map { |fun| Eth::Contract::Function.new(fun) } }

  it "creates Function objects" do
    expect(functions[0].class).to eq(Eth::Contract::Function)
    expect(functions[0].name).to eq("allowance")
    expect(functions[0].constant).to be_nil
    expect(functions[0].function_string).to eq("allowance(address,address)")
    expect(functions[0].inputs.size).to eq(2)
    expect(functions[0].inputs[0].name).to eq("owner")
    expect(functions[0].inputs[0].type).to eq("address")
    expect(functions[0].inputs[1].name).to eq("spender")
    expect(functions[0].inputs[1].type).to eq("address")
    expect(functions[0].outputs[0].name).to eq("")
    expect(functions[0].outputs[0].type).to eq("uint256")
    expect(functions[0].signature).to eq("dd62ed3e")
  end

  it ".calc_signature(name, inputs)" do
    signature_1 = Contract::Function.calc_signature(functions[0].name, functions[0].inputs)
    expect(signature_1).to eq("allowance(address,address)")
    signature_2 = Contract::Function.calc_signature(functions[1].name, functions[1].inputs)
    expect(signature_2).to eq("approve(address,uint256)")
  end

  it ".encoded_function_signature(signature)" do
    signature = Contract::Function.calc_signature(functions[0].name, functions[0].inputs)
    expect(Contract::Function.encoded_function_signature(signature)).to eq("dd62ed3e")
  end

  context "with tuple params" do
    let(:erc20_abi_file) { File.read "spec/fixtures/abi/Tuple.json" }
    let(:abi) { JSON.parse erc20_abi_file }
    subject(:functions) { abi.select { |x| x["type"] == "function" }.map { |fun| Eth::Contract::Function.new(fun) } }

    it "calculates signature with tuple params" do
      signature = Contract::Function.calc_signature(functions[0].name, functions[0].inputs)
      expect(Contract::Function.encoded_function_signature(signature)).to eq("b68f14a0")
    end
  end

  context "with complex tuple params" do
    let(:erc20_abi_file) { File.read "spec/fixtures/abi/Tuple2.json" }
    let(:abi) { JSON.parse erc20_abi_file }
    subject(:functions) { abi.select { |x| x["type"] == "function" }.map { |fun| Eth::Contract::Function.new(fun) } }

    it "calculates signature with tuple params" do
      signature = Contract::Function.calc_signature(functions[0].name, functions[0].inputs)
      expect(Contract::Function.encoded_function_signature(signature)).to eq("1b9faea1")
    end
  end

  describe "#encode_call" do
    it "encodes function arguments" do
      expect(
        functions[0].encode_call("0xA64d0659990256F7669cf3BcF422998aAE7536f5", "0x6f813e6430a223e3ac285144fa9857cb38a642a6")
      ).to eq("0xdd62ed3e000000000000000000000000a64d0659990256f7669cf3bcf422998aae7536f50000000000000000000000006f813e6430a223e3ac285144fa9857cb38a642a6")
    end
  end

  describe "#decode_call_result" do
    it "decodes call result" do
      expect(
        functions[0].decode_call_result("0x00000000000000000000000000000000000000000000000000000000000000af")
      ).to eq([175])
    end
  end
end
