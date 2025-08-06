# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Abi do
  describe "ZST robustness" do
    it "rejects self-referential dynamic array offsets" do
      payload = "0000000000000000000000000000000000000000000000000000000000000020" \
                "0000000000000000000000000000000000000000000000000000000000000002" \
                "0000000000000000000000000000000000000000000000000000000000000020" \
                "0000000000000000000000000000000000000000000000000000000000000020"
      data = Util.hex_to_bin(payload)
      expect { Abi.decode(["uint256[][]"], data) }.to raise_error Abi::DecodingError
    end
  end
end
