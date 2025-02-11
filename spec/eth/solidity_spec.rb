require "spec_helper"

describe Solidity do
  it "finds a solc compiler" do
    # This fails if no `solc` is in the $PATH.
    expect(Solidity.new).to be
    expect(Solidity.new(system("which", "solc", :out => File::NULL))).to be
  end

  subject(:solc) { Solidity.new }

  it "compiles the dummy contract" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/dummy.sol"
    result = solc.compile contract
    expect(result.keys).to eq ["Dummy"]
    expect(result["Dummy"]["abi"]).to eq JSON.parse '[{"inputs":[],"name":"get","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"x","type":"uint256"}],"name":"set","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
    expect(result["Dummy"]["bin"]).to start_with "608080604052"
  end

  it "compiles the greeter contract" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/greeter.sol"
    result = solc.compile contract
    expect(result.keys).to eq ["Greeter", "Mortal"]
    expect(result["Mortal"]["abi"]).to eq JSON.parse '[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
    expect(result["Greeter"]["abi"]).to eq JSON.parse '[{"inputs":[{"internalType":"string","name":"message","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"greet","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"message","type":"string"}],"name":"setGreeting","outputs":[],"stateMutability":"nonpayable","type": "function"}]'
    expect(result["Mortal"]["bin"]).to start_with "608080604052"
    expect(result["Greeter"]["bin"]).to start_with "6080604052"
  end

  it "deploys an ethereum-consensus deposit contract" do
    geth = Client.create "/tmp/geth.ipc"
    contract = "#{Dir.pwd}/spec/fixtures/contracts/deposit.sol"
    result = solc.compile contract
    expect(result["DepositContract"]).to be
    payload = result["DepositContract"]["bin"]
    expect(payload).to start_with "60"
    expect(payload).to end_with "33"
    params = {
      from: geth.default_account,
      priority_fee: 0,
      max_gas_fee: Unit::GWEI,
      gas_limit: Tx.estimate_intrinsic_gas(payload),
      data: payload,
    }
    deploy = geth.eth_send_transaction(params)
    hash = deploy["result"]
    expect(hash).to start_with "0x"
    geth.wait_for_tx hash
    receipt = geth.eth_get_transaction_receipt hash
    expect(receipt["result"]).to be
    address = receipt["result"]["contractAddress"]
    expect(address).to be
    expect { Address.new address }.not_to raise_error
  end

  it "handles file-system errors" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/null.sol"
    expect { solc.compile contract }.to raise_error Errno::ENOENT, /No such file or directory - Contract file not found:/
  end

  it "handles compiler errors" do
    contract = "#{Dir.pwd}/spec/fixtures/contracts/error.sol"
    expect { solc.compile contract }.to raise_error Solidity::CompilerError, /Error: Identifier not found or not unique./
  end
end
