require "spec_helper"

describe Client do
  subject(:geth) { Client.create "/tmp/geth.ipc" }

  describe ".request_validator_withdrawal" do
    it "requests a validator withdrawal" do
      fee = geth.withdrawal_request_fee
      expect(fee).to be >= 0
      pubkey = "0x" + ("11" * 48)
      tx_hash = geth.request_validator_withdrawal(pubkey, 1)
      expect(tx_hash).to start_with "0x"
      geth.wait_for_tx tx_hash
      receipt = geth.eth_get_transaction_receipt tx_hash
      expect(receipt["result"]).to be
    end
  end
end
