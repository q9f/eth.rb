require "spec_helper"

describe Eth::Deposit do
  let(:contract) { described_class.contract("0x0000000000000000000000000000000000000000") }

  it "builds deposit contract wrapper" do
    expect(contract.function("deposit")).to be
    expect(contract.events.find { |e| e.name == "DepositEvent" }).to be
  end

  it "submits deposits via client" do
    client = double("client")
    pubkey = "0x01"
    withdrawal = "0x02"
    signature = "0x03"
    root = "0x" + "04" * 32
    allow(described_class).to receive(:contract).and_return(contract)
    expect(client).to receive(:transact).with(
      contract,
      "deposit",
      pubkey,
      withdrawal,
      signature,
      root,
      tx_value: 32,
    )
    described_class.deposit(client, pubkey, withdrawal, signature, root, value: 32)
  end

  it "parses deposit events" do
    event = contract.events.find { |e| e.name == "DepositEvent" }
    data = Eth::Abi.encode(["bytes", "bytes", "bytes", "bytes", "bytes"], ["\x01", "\x02", "\x03", "\x04", "\x05"])
    log = {
      "address" => contract.address,
      "topics" => ["0x" + Digest::Keccak.hexdigest(event.event_string, 256)],
      "data" => "0x#{data.unpack1("H*")}",
    }
    parsed = described_class.parse_deposit_event(log)
    expect(parsed[:pubkey]).to eq("0x01")
    expect(parsed[:withdrawal_credentials]).to eq("0x02")
    expect(parsed[:amount]).to eq("0x03")
    expect(parsed[:signature]).to eq("0x04")
    expect(parsed[:index]).to eq("0x05")
  end

  it "exposes dev_add_deposit rpc command" do
    expect(Eth::Client.new(nil)).to respond_to(:dev_add_deposit)
  end
end
