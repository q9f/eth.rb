require "spec_helper"

describe Solidity do
  it "finds a solc compiler" do

    # This fails if no `solc` is in the $PATH.
    expect(Solidity.new).to be
  end

  subject(:solc) { Solidity.new }

  it "compiles the dummy contract" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/dummy.sol"
    result = solc.compile contract
    expect(result.keys).to eq ["Dummy"]
    expect(result["Dummy"]["abi"]).to eq JSON.parse '[{"inputs":[],"name":"get","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"x","type":"uint256"}],"name":"set","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
    expect(result["Dummy"]["bin"]).to start_with "6080604052348015600f57600080fd5b5060"
  end

  it "compiles the greeter contract" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/greeter.sol"
    result = solc.compile contract
    expect(result.keys).to eq ["Greeter", "Mortal"]
    expect(result["Mortal"]["abi"]).to eq JSON.parse '[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
    expect(result["Greeter"]["abi"]).to eq JSON.parse '[{"inputs":[{"internalType":"string","name":"message","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"greet","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
    expect(result["Mortal"]["bin"]).to start_with "6080604052348015600f57600080fd5b5060"
    expect(result["Greeter"]["bin"]).to start_with "608060405234801561001057600080fd5b5060"
  end

  it "handles compiler errors" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/error.sol"
    expect { solc.compile contract }.to raise_error Solidity::CompilerError, /Error: Identifier not found or not unique./
  end
end
