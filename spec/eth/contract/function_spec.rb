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
end
