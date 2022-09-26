require "spec_helper"

describe Contract::FunctionInput do
  subject(:function_input) { Contract::FunctionInput.new({ "name" => "amount", "type" => "uint256" }) }
  it "creates FunctionInput objects" do
    expect(function_input.name).to eq("amount")
    expect(function_input.type).to eq("uint256")
    expect(function_input).to be_instance_of Contract::FunctionInput
  end

  context "with an array type" do
    subject(:function_with_array) { Contract::FunctionInput.new({ "name" => "array", "type" => "uint256[]" }) }
    it "creates FunctionInput objects" do
      expect(function_with_array.name).to eq("array")
      expect(function_with_array.type).to eq("uint256[]")
      expect(function_with_array).to be_instance_of Contract::FunctionInput
    end
  end
end
