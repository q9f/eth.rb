require "spec_helper"

describe Contract do
  let(:abi) do
    [
      { "type" => "function", "name" => "foo", "inputs" => [], "outputs" => [] },
      {
        "type" => "error",
        "name" => "Unauthorized",
        "inputs" => [{ "name" => "addr", "type" => "address" }],
      },
    ]
  end

  let(:contract) do
    Contract.from_abi(abi: abi, address: Address::ZERO, name: "Foo")
  end

  let(:error_data) do
    sig = contract.errors.first.signature
    encoded = Util.bin_to_hex(Abi.encode(["address"], [Address::ZERO]))
    sig + encoded
  end

  describe "#call with custom error" do
    let(:client) { Client.new(nil) }

    it "decodes custom error data" do
      allow(client).to receive(:eth_call).and_raise(Client::RpcError.new("execution reverted", error_data))
      expect { client.call(contract, "foo") }.to raise_error(Client::ContractExecutionError, "execution reverted: Unauthorized(0x0000000000000000000000000000000000000000)")
    end
  end

  describe "#decode_error" do
    let(:rpc_error) { Client::RpcError.new("execution reverted", error_data) }

    it "returns a readable message" do
      expect(contract.decode_error(rpc_error)).to eq("execution reverted: Unauthorized(0x0000000000000000000000000000000000000000)")
    end
  end
end
