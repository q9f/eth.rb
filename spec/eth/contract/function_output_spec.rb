require "spec_helper"

describe Contract::FunctionOutput do
  subject(:function_output) { Contract::FunctionOutput.new({ "name" => "amount", "type" => "uint256" }) }
  it "creates FunctionOutput objects" do
    expect(function_output.name).to eq("amount")
    expect(function_output.type).to eq("uint256")
    expect(function_output).to be_instance_of Contract::FunctionOutput
  end
end
