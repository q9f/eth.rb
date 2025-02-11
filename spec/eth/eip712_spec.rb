require "spec_helper"

describe Eip712 do

  # The EIP-712 domain specification descriptor.
  subject(:eip712_domain) {
    [
      { :name => "name", :type => "string" },
      { :name => "version", :type => "string" },
      { :name => "chainId", :type => "uint256" },
      { :name => "verifyingContract", :type => "address" },
    ]
  }

  # A Person type descriptor with a name and a wallet.
  subject(:person) {
    [
      { :name => "name", :type => "string" },
      { :name => "wallet", :type => "address" },
    ]
  }

  # A Mail type descriptor with from, to, and contents.
  subject(:mail) {
    [
      { :name => "from", :type => "Person" },
      { :name => "to", :type => "Person" },
      { :name => "contents", :type => "string" },
    ]
  }

  # The app-specific domain data.
  subject(:domain_data) {
    {
      :name => "Ether Mail",
      :version => "1",
      :chainId => Chain::ETHEREUM,
      :verifyingContract => Address.new("0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"),
    }
  }

  # The message data to sign.
  subject(:message_data) {
    {
      :from => {
        :name => "Cow",
        :wallet => Address.new("0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"),
      },
      :to => {
        :name => "Bob",
        :wallet => Address.new("0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"),
      },
      :contents => "Hello, Bob!",
    }
  }

  # The entire EIP-712 conform typed-data structure.
  subject(:typed_data) {
    {
      :types => {
        :EIP712Domain => eip712_domain,
        :Person => person,
        :Mail => mail,
      },
      :primaryType => "Mail",
      :domain => domain_data,
      :message => message_data,
    }
  }

  # Retroactively extracting the nested types for convenience.
  subject(:types) { typed_data[:types] }

  describe ".type_dependencies" do
    it "can find types and their nested type dependencies recursively" do
      expect(Eip712.type_dependencies "EIP712Domain", types).to eq ["EIP712Domain"]
      expect(Eip712.type_dependencies "Person", types).to eq ["Person"]
      expect(Eip712.type_dependencies "Mail", types).to eq ["Mail", "Person"]
      expect(Eip712.type_dependencies "address", types).to eq []
      expect(Eip712.type_dependencies "string", types).to eq []
      expect(Eip712.type_dependencies "uint256", types).to eq []
    end
  end

  describe ".encode_type" do
    it "can encode types as string mappings with field names" do
      expect(Eip712.encode_type "EIP712Domain", types).to eq "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
      expect(Eip712.encode_type "Person", types).to eq "Person(string name,address wallet)"
      expect(Eip712.encode_type "Mail", types).to eq "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
    end

    it "raises errors for non-primary types" do
      expect { Eip712.encode_type "address", types }.to raise_error Eip712::TypedDataError, "Non-primary type found: address!"
      expect { Eip712.encode_type "string", types }.to raise_error Eip712::TypedDataError, "Non-primary type found: string!"
      expect { Eip712.encode_type "uint256", types }.to raise_error Eip712::TypedDataError, "Non-primary type found: uint256!"
    end
  end

  describe ".hash_type" do
    it "can hash types mappings with field names" do
      expect(Util.bin_to_hex Eip712.hash_type "EIP712Domain", types).to eq "8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f"
      expect(Util.bin_to_hex Eip712.hash_type "Person", types).to eq "b9d8c78acf9b987311de6c7b45bb6a9c8e1bf361fa7fd3467a2163f994c79500"
      expect(Util.bin_to_hex Eip712.hash_type "Mail", types).to eq "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
    end
  end

  describe ".encode_data" do
    it "can abi-encode structured typed data" do
      expect(Eip712.encode_data "EIP712Domain", domain_data, types).to eq Util.hex_to_bin "0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400fc70ef06638535b4881fafcac8287e210e3769ff1a8e91f1b95d6246e61e4d3c6c89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc60000000000000000000000000000000000000000000000000000000000000001000000000000000000000000cccccccccccccccccccccccccccccccccccccccc"
      expect(Eip712.encode_data "Mail", message_data, types).to eq Util.hex_to_bin "0xa0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8"
      expect(Eip712.encode_data "Person", message_data[:to], types).to eq Util.hex_to_bin "0xb9d8c78acf9b987311de6c7b45bb6a9c8e1bf361fa7fd3467a2163f994c7950028cac318a86c8a0a6a9156c2dba2c8c2363677ba0514ef616592d81557e679b6000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
      expect(Eip712.encode_data "Person", message_data[:from], types).to eq Util.hex_to_bin "0xb9d8c78acf9b987311de6c7b45bb6a9c8e1bf361fa7fd3467a2163f994c795008c1d2bd5348394761719da11ec67eedae9502d137e8940fee8ecd6f641ee1648000000000000000000000000cd2a3d9f938e13cd947ec05abc7fe734df8dd826"
    end
  end

  describe ".hash_data" do
    it "can hash structured data" do
      expect(Eip712.hash_data "EIP712Domain", domain_data, types).to eq Util.hex_to_bin "0xf2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
      expect(Eip712.hash_data "Mail", message_data, types).to eq Util.hex_to_bin "0xc52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e"
      expect(Eip712.hash_data "Person", message_data[:to], types).to eq Util.hex_to_bin "0xcd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1"
      expect(Eip712.hash_data "Person", message_data[:from], types).to eq Util.hex_to_bin "0xfc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8"
    end
  end

  describe ".hash" do
    it "can hash the eip-712 typed data" do
      expect(Eip712.hash typed_data).to eq Util.hex_to_bin "0xbe609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
    end
  end

  context "eip 712 arrays" do
    subject(:domain) {
      [
        { name: "name", type: "string" },
        { name: "version", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
        { name: "salt", type: "bytes32" },
      ]
    }

    subject(:sell_orders) {
      [
        { name: "id", type: "uint256[]" },
        { name: "tokenId", type: "uint256[]" },
        { name: "price", type: "uint256[]" },
        { name: "proto", type: "uint256[]" },
        { name: "purity", type: "uint256[]" },
        { name: "seller", type: "address" },
      ]
    }

    subject(:card_exchange_contract) { Address.new("0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC") }

    subject(:domain_data) {
      {
        name: "app",
        version: "1",
        chainId: 3,
        verifyingContract: card_exchange_contract,
        salt: "0xa222082684812afae4e093416fff16bc218b569abe4db590b6a058e1f2c1cd3e",
      }
    }

    subject(:address) { Address.new "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826" }

    subject(:message) {
      {
        id: [1],
        tokenId: [1],
        price: [1],
        proto: [1],
        purity: [1],
        seller: address,
      }
    }

    subject(:data) {
      {
        :types => {
          :EIP712Domain => domain,
          :SellOrders => sell_orders,
        },
        :primaryType => "SellOrders",
        :domain => domain_data,
        :message => message,
      }
    }

    it "encodes arrays in an eip 712 domain" do
      expect(Eip712.encode_type "EIP712Domain", data[:types]).to eq "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
      expect(Eip712.encode_type "SellOrders", data[:types]).to eq "SellOrders(uint256[] id,uint256[] tokenId,uint256[] price,uint256[] proto,uint256[] purity,address seller)"

      expect(Util.bin_to_hex(Eip712.encode_data("EIP712Domain", domain_data, data[:types]))).to eq "d87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472d6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fbc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc60000000000000000000000000000000000000000000000000000000000000003000000000000000000000000cccccccccccccccccccccccccccccccccccccccca222082684812afae4e093416fff16bc218b569abe4db590b6a058e1f2c1cd3e"
      pending("https://github.com/q9f/eth.rb/issues/127")
      expect(Util.bin_to_hex(Eip712.encode_data("SellOrders", message, data[:types]))).to eq "58682cd513b67511a4ef89156104cf2bc7835c7289308bb112fdafe49897324200000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000cd2a3d9f938e13cd947ec05abc7fe734df8dd8260000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001"
    end
  end

  context "end to end" do
    it "can hash the correct data type" do
      key = Key.new(priv: "0x8e589ba6280400cfa426229684f7c2ac9ebf132f7ad658a82ed57553a0a9dee8")
      data = "0xa2d6eae3"
      domain = {
        name: "Complex Data",
        version: "1",
        chainId: 421613,
        verifyingContract: "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
      }

      type_bytes = [{ name: "data", type: "bytes" }]
      data_bytes = {
        types: {
          EIP712Domain: eip712_domain,
          Data: type_bytes,
        },
        primaryType: "Data",
        domain: domain,
        message: {
          data: data,
        },
      }
      sig_bytes = "ddefbbe703f59949a87ece451321924bb9297100dda63e1f39559b72db3ec9e83dae2056c25b52ddb8bd53ab536e84d2e4f70d98219ed14e46b021a59aefb4eb1c"
      expect(key.sign_typed_data data_bytes).to eq sig_bytes

      type_string = [{ name: "data", type: "string" }]
      data_string = {
        types: {
          EIP712Domain: eip712_domain,
          Data: type_string,
        },
        primaryType: "Data",
        domain: domain,
        message: {
          data: data,
        },
      }
      sig_string = "8255c17ce6be5fb6ee3430784a52a5163c63fc87e2dcae32251d9c49ba849fad7067454b0d7e694698c02e552fd7af283dcaadc754d58ecba978856de8742e361b"
      expect(key.sign_typed_data data_string).to eq sig_string
    end
  end
end
