require 'spec_helper'

describe Eth::Eip712 do

  # The EIP-712 domain specifcation descriptor.
  subject(:eip712_domain) {[
    { :name => "name", :type => "string" },
    { :name => "version", :type => "string" },
    { :name => "chainId", :type => "uint256" },
    { :name => "verifyingContract", :type => "address" },
  ]}

  # A Person type descriptor with a name and a wallet.
  subject(:person) {[
    { :name => "name", :type => "string" },
    { :name => "wallet", :type => "address" },
  ]}

  # A Mail type descriptor with from, to, and contents.
  subject(:mail) {[
    { :name => "from", :type => "Person" },
    { :name => "to", :type => "Person" },
    { :name => "contents", :type => "string" },
  ]}

  # The app-specific domain data.
  subject(:domain_data) {{
    :name => "Ether Mail",
    :version => "1",
    :chainId => Eth::Chain::ETHEREUM,
    :verifyingContract => Eth::Address.new("0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC").checksummed,
  }}

  # The message data to sign.
  subject(:message_data) {{
    :from => {
      :name => "Cow",
      :wallet => Eth::Address.new("0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826").checksummed,
    },
    :to => {
      :name => "Bob",
      :wallet => Eth::Address.new("0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB").checksummed,
    },
    :contents => "Hello, Bob!",
  }}

  # The entire EIP-712 conform typed-data structure.
  subject(:typed_data) {{
    :types => {
      :EIP712Domain => eip712_domain,
      :Person => person,
      :Mail => mail,
    },
    :primaryType => "Mail",
    :domain => domain_data,
    :message => message_data
  }}

  # Retroactively extracting the nested types for convenience.
  subject(:types) { typed_data[:types] }

  describe ".type_dependencies" do
    it "can find types and their nested type dependencies recursively" do
      expect(Eth::Eip712.type_dependencies "EIP712Domain", types).to eq ["EIP712Domain"]
      expect(Eth::Eip712.type_dependencies "Person", types).to eq ["Person"]
      expect(Eth::Eip712.type_dependencies "Mail", types).to eq ["Mail", "Person"]
      expect(Eth::Eip712.type_dependencies "address", types).to eq []
      expect(Eth::Eip712.type_dependencies "string", types).to eq []
      expect(Eth::Eip712.type_dependencies "uint256", types).to eq []
    end
  end

  describe ".encode_type" do
    it "can encode types as string mappings with field names" do
      expect(Eth::Eip712.encode_type "EIP712Domain", types).to eq "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
      expect(Eth::Eip712.encode_type "Person", types).to eq "Person(string name,address wallet)"
      expect(Eth::Eip712.encode_type "Mail", types).to eq "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
    end

    it "raises errors for non-primary types" do
      expect {Eth::Eip712.encode_type "address", types}.to raise_error ArgumentError
      expect {Eth::Eip712.encode_type "string", types}.to raise_error ArgumentError
      expect {Eth::Eip712.encode_type "uint256", types}.to raise_error ArgumentError
    end
  end

  describe ".hash_type" do
    it "can hash types mappings with field names" do
      expect(Eth::Util.bin_to_hex Eth::Eip712.hash_type "EIP712Domain", types).to eq "8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f"
      expect(Eth::Util.bin_to_hex Eth::Eip712.hash_type "Person", types).to eq "b9d8c78acf9b987311de6c7b45bb6a9c8e1bf361fa7fd3467a2163f994c79500"
      expect(Eth::Util.bin_to_hex Eth::Eip712.hash_type "Mail", types).to eq "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
    end
  end
end
