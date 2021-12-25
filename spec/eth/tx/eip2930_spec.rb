require "spec_helper"

describe Eth::Tx::Eip2930Payload do
  describe ".initialize" do
    it "creates EIP-2930 transaction payload objects" do
      expect(Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT, 0)).to be
      expect(Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT, 0)).to be_instance_of Eth::Tx::Eip2930Payload
    end

    it "doesn't create invalid transaction payload objects" do
      expect { Eth::Tx::Eip2930Payload.new(-9 * Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT, 0) }.to raise_error ArgumentError
      expect { Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::DEFAULT_LIMIT - 1, 0) }.to raise_error ArgumentError
      expect { Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT + 1, 0) }.to raise_error ArgumentError
      expect { Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT, -1) }.to raise_error ArgumentError
      expect { Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT, 0, "foo") }.to raise_error ArgumentError
      expect { Eth::Tx::Eip2930Payload.new(Eth::Unit::GWEI, Eth::Tx::BLOCK_LIMIT, 0, "0xef26b1f67797e7a5a3c192c93d821fadef3ba173", -1) }.to raise_error ArgumentError
    end
  end
end
