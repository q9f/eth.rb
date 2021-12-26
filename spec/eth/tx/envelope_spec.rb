require "spec_helper"

describe Eth::Tx::Envelope do
  subject(:default_payload) { Eth::Tx::Eip1559Payload.new(Eth::Unit::GWEI, Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT, 0) }
  describe ".initialize" do
    it "creates EIP-2718 transaction envelope objects" do
      expect(Eth::Tx::Envelope.new(default_payload)).to be
      expect(Eth::Tx::Envelope.new(default_payload)).to be_instance_of Eth::Tx::Envelope
    end

    it "doesn't create invalid transaction envelope objects" do
      expect { Eth::Tx::Envelope.new(default_payload, 3) }.to raise_error ArgumentError
      expect { Eth::Tx::Envelope.new(["Foo", "Bar", 0], Eth::Tx::TYPE_2930) }.to raise_error ArgumentError
    end
  end
end
