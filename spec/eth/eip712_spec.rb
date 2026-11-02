require "spec_helper"
require "delegate"
require "set"

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

  describe ".encode_value" do
    it "abi-encodes primitive values" do
      expect(Eip712.encode_value("uint256", 1, {})).to eq Abi.encode(["uint256"], [1])
    end
  end

  # EIP-712 encodes an array as "the keccak256 hash of the concatenated
  # encodeData of their contents": one 32-byte word per array.
  describe ".encode_array" do
    it "hashes string array items" do
      expect(Eip712.encode_array("string[]", ["foo", "bar"], {})).to eq Util.keccak256(Util.keccak256("foo") + Util.keccak256("bar"))
    end

    it "hashes bytes array items" do
      arr = ["0x1234", "0xabcd"]
      expected = Util.keccak256(arr.map { |v| Util.keccak256(Util.hex_to_bin(v)) }.join)
      expect(Eip712.encode_array("bytes[]", arr, {})).to eq expected
    end

    it "hashes struct array items" do
      types = { Person: person }
      people = [
        { name: "Cow", wallet: Address.new("0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826") },
        { name: "Bob", wallet: Address.new("0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB") },
      ]
      # hashStruct of Cow and Bob, as the EIP-712 reference example publishes them
      cow_hash = Util.hex_to_bin "fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8"
      bob_hash = Util.hex_to_bin "cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1"
      expect(Eip712.encode_array("Person[]", people, types)).to eq Util.keccak256(cow_hash + bob_hash)
    end

    it "recursively encodes nested arrays" do
      nested = [["foo"], ["bar"]]
      expected = Util.keccak256(nested.map { |inner| Util.keccak256(inner.map { |v| Util.keccak256(v) }.join) }.join)
      expect(Eip712.encode_array("string[][]", nested, {})).to eq expected
    end

    it "abi-encodes atomic array items as 32-byte words" do
      one = Util.hex_to_bin "0000000000000000000000000000000000000000000000000000000000000001"
      two = Util.hex_to_bin "0000000000000000000000000000000000000000000000000000000000000002"
      expect(Eip712.encode_array("uint256[]", [1, 2], {})).to eq Util.keccak256(one + two)
    end

    it "hashes nil and empty arrays as keccak-256 of nothing" do
      empty = Util.hex_to_bin "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      expect(Eip712.encode_array("uint256[]", nil, {})).to eq empty
      expect(Eip712.encode_array("uint256[]", [], {})).to eq empty
      expect(Eip712.encode_array("Person[]", [], { Person: person })).to eq empty
    end

    it "raises for a fixed-size array of the wrong length" do
      expect { Eip712.encode_array("uint256[2]", [1, 2, 3], {}) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
      expect { Eip712.encode_array("uint256[2]", [1], {}) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 1 provided"
      expect { Eip712.encode_array("uint256[2]", nil, {}) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 0 provided"
      expect { Eip712.encode_array("Person[1]", [], { Person: person }) }.to raise_error Abi::EncodingError, "Expecting 1 elements: 0 provided"
    end

    it "raises for an invalid base type, empty or not" do
      expect { Eip712.encode_array("uint7[]", [], {}) }.to raise_error Abi::Type::ParseError, "Integer size out of bounds"
      expect { Eip712.encode_array("uint7[]", [1], {}) }.to raise_error Abi::Type::ParseError, "Integer size out of bounds"
      expect { Eip712.encode_array("Persn[]", [], {}) }.to raise_error Abi::Type::ParseError, "Invalid type format"
      expect { Eip712.encode_array("Person[x]", [], { Person: person }) }.to raise_error Abi::Type::ParseError, "Invalid type format"
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

      # EIP-712 encodes each uint256[] member as one word, the keccak-256 of
      # its elements' 32-byte words: for [1], keccak256(uint256(1)), not the
      # ABI offset and tail this example asserted before #420.
      type_hash = "58682cd513b67511a4ef89156104cf2bc7835c7289308bb112fdafe498973242"
      one = "b10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6"
      seller = "000000000000000000000000cd2a3d9f938e13cd947ec05abc7fe734df8dd826"
      expect(Util.bin_to_hex(Eip712.encode_data("SellOrders", message, data[:types]))).to eq type_hash + one * 5 + seller
    end
  end

  # EIP-712 encodes every member as exactly 32 bytes, and an array as "the
  # keccak256 hash of the concatenated encodeData of their contents (i.e. the
  # encoding of SomeType[5] is identical to that of a struct containing five
  # members of type SomeType)". No official vector has array fields, so these
  # expectations are built from that definition and the hashes the EIP-712
  # reference example publishes, never from the code under test.
  # Ref: https://eips.ethereum.org/EIPS/eip-712
  context "array fields" do

    # Published by the reference example for its Mail message: hashStruct(from),
    # hashStruct(to), keccak256(contents), the domain separator and the digest.
    subject(:cow_hash) { Util.hex_to_bin "fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8" }
    subject(:bob_hash) { Util.hex_to_bin "cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1" }
    subject(:contents_hash) { Util.hex_to_bin "b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8" }
    subject(:domain_separator) { Util.hex_to_bin "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f" }
    subject(:reference_digest) { "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2" }

    # The reference example's signer.
    subject(:cow) { Key.new priv: Util.keccak256("cow") }

    # The reference Mail type with `to` as an array of Person.
    subject(:mail_with_array) {
      {
        Person: person,
        Mail: [
          { name: "from", type: "Person" },
          { name: "to", type: "Person[]" },
          { name: "contents", type: "string" },
        ],
      }
    }

    # The type hash, then one 32-byte word per member, which hashStruct hashes
    # and Eip712.encode_data returns; EIP-712's encodeData is the words alone.
    def definition_data(type_string, words)
      Util.keccak256(type_string) + words.join
    end

    # The digest by definition: keccak256(0x19 0x01 domainSeparator hashStruct(message)).
    def definition_digest(encoded_data)
      Util.bin_to_hex Util.keccak256("\x19\x01".b + domain_separator + Util.keccak256(encoded_data))
    end

    # A uint256 member: big-endian, left-padded to 32 bytes.
    def uint_word(value)
      [value.to_s(16).rjust(64, "0")].pack("H*")
    end

    # An address member: encoded as uint160.
    def address_word(address)
      [address.to_s.delete_prefix("0x").downcase.rjust(64, "0")].pack("H*")
    end

    # Proves both definition helpers on the reference example before an array
    # field relies on them.
    def expect_reference_digest
      type_string = "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
      encoded = definition_data(type_string, [cow_hash, bob_hash, contents_hash])
      expect(definition_digest(encoded)).to eq reference_digest
    end

    # Typed data in the reference domain.
    def typed_data_for(primary_type, types, message)
      {
        types: { EIP712Domain: eip712_domain }.merge(types),
        primaryType: primary_type,
        domain: domain_data,
        message: message,
      }
    end

    it "hashes a struct array field to one word" do
      expect_reference_digest
      type_string = "Mail(Person from,Person[] to,string contents)Person(string name,address wallet)"
      expect(Eip712.encode_type "Mail", mail_with_array).to eq type_string

      # to: [Bob] encodes like a struct with one Person member
      to_bob = message_data.merge(to: [message_data[:to]])
      expected = definition_data(type_string, [cow_hash, Util.keccak256(bob_hash), contents_hash])
      expect(Util.bin_to_hex Eip712.encode_data("Mail", to_bob, mail_with_array)).to eq Util.bin_to_hex(expected)
      expect(Util.bin_to_hex Eip712.hash(typed_data_for("Mail", mail_with_array, to_bob))).to eq definition_digest(expected)
      expect(definition_digest(expected)).to eq "e3e147d255f92f5a9de155defefb2816b1ca970e975b38baadb0cca27e733d36"

      # to: [Bob, Cow] hashes both hashStructs in order
      to_both = message_data.merge(to: [message_data[:to], message_data[:from]])
      expected = definition_data(type_string, [cow_hash, Util.keccak256(bob_hash + cow_hash), contents_hash])
      expect(Util.bin_to_hex Eip712.encode_data("Mail", to_both, mail_with_array)).to eq Util.bin_to_hex(expected)
      expect(Util.bin_to_hex Eip712.hash(typed_data_for("Mail", mail_with_array, to_both))).to eq definition_digest(expected)
      expect(definition_digest(expected)).to eq "50d4befabf72490759475adbb303a9cc3321af8279c7a76e368cf7405f9741c6"
    end

    it "signs and recovers typed data with a struct array field" do
      expect_reference_digest
      type_string = "Mail(Person from,Person[] to,string contents)Person(string name,address wallet)"
      mail = typed_data_for("Mail", mail_with_array, message_data.merge(to: [message_data[:to]]))
      digest = definition_digest(definition_data(type_string, [cow_hash, Util.keccak256(bob_hash), contents_hash]))
      signature = cow.sign_typed_data mail
      expect(signature).to eq cow.sign(Util.hex_to_bin(digest))
      expect(Signature.recover_typed_data mail, signature).to eq cow.public_hex
      expect(Signature.verify mail, signature, cow.address).to be true
    end

    it "hashes atomic array fields, dynamic and fixed-size, to one word" do
      expect_reference_digest
      type_string = "Atoms(uint256[] ids,address[] wallets,uint256[2] pair)"
      types = {
        Atoms: [
          { name: "ids", type: "uint256[]" },
          { name: "wallets", type: "address[]" },
          { name: "pair", type: "uint256[2]" },
        ],
      }
      wallets = [message_data[:from][:wallet], message_data[:to][:wallet]]
      message = { ids: [1, 2, 3], wallets: wallets, pair: [1, 2] }
      expected = definition_data(type_string, [
        Util.keccak256(uint_word(1) + uint_word(2) + uint_word(3)),
        Util.keccak256(wallets.map { |w| address_word w }.join),
        Util.keccak256(uint_word(1) + uint_word(2)),
      ])
      expect(Util.bin_to_hex Eip712.encode_data("Atoms", message, types)).to eq Util.bin_to_hex(expected)
      expect(Util.bin_to_hex Eip712.hash(typed_data_for("Atoms", types, message))).to eq definition_digest(expected)
      expect(definition_digest(expected)).to eq "2e62a3b0b12124b04507c14ab837527e36064b5fad536ec5fc557bd2ee951eb5"
    end

    it "hashes string and bytes array fields whose element hashes begin with 30 78" do
      expect_reference_digest

      # both element hashes begin with the bytes of "0x", which the ABI string
      # and bytes encoders read as hex, so the array path must not pass
      # element hashes through Abi.encode
      expect(Util.keccak256("Hello, Bob! 161461")[0, 2]).to eq "0x"
      expect(Util.keccak256(Util.hex_to_bin("0x313232363534"))[0, 2]).to eq "0x"

      type_string = "Tags(string[] tags,bytes[] blobs)"
      types = { Tags: [{ name: "tags", type: "string[]" }, { name: "blobs", type: "bytes[]" }] }
      message = { tags: ["Hello, Bob!", "Hello, Bob! 161461"], blobs: ["0x313232363534"] }
      expected = definition_data(type_string, [
        Util.keccak256(contents_hash + Util.keccak256("Hello, Bob! 161461")),
        Util.keccak256(Util.keccak256(Util.hex_to_bin("0x313232363534"))),
      ])
      expect(Util.bin_to_hex Eip712.encode_data("Tags", message, types)).to eq Util.bin_to_hex(expected)
      expect(Util.bin_to_hex Eip712.hash(typed_data_for("Tags", types, message))).to eq definition_digest(expected)
      expect(definition_digest(expected)).to eq "41ba1f8d33b8c8d799702da8117ad96d735d8476a2f5a157099ce25c7d9e0027"
    end

    it "hashes nested array fields recursively" do
      expect_reference_digest
      type_string = "Grid(uint256[][] grid,Person[][] teams)Person(string name,address wallet)"
      types = { Person: person, Grid: [{ name: "grid", type: "uint256[][]" }, { name: "teams", type: "Person[][]" }] }
      expect(Eip712.encode_type "Grid", types).to eq type_string
      message = { grid: [[1], [2, 3]], teams: [[message_data[:to], message_data[:from]], []] }
      expected = definition_data(type_string, [
        Util.keccak256(Util.keccak256(uint_word(1)) + Util.keccak256(uint_word(2) + uint_word(3))),
        Util.keccak256(Util.keccak256(bob_hash + cow_hash) + Util.keccak256("")),
      ])
      expect(Util.bin_to_hex Eip712.encode_data("Grid", message, types)).to eq Util.bin_to_hex(expected)
      expect(Util.bin_to_hex Eip712.hash(typed_data_for("Grid", types, message))).to eq definition_digest(expected)
      expect(definition_digest(expected)).to eq "62c8067c420c3b210dc19c32d54300daadb9d37f644c6e294113d9890dfd75f1"
    end

    it "hashes a nil or empty array field as keccak-256 of nothing" do
      expect_reference_digest
      types = { List: [{ name: "list", type: "uint256[]" }] }
      expected = definition_data("List(uint256[] list)", [Util.keccak256("")])
      expect(Util.bin_to_hex Eip712.encode_data("List", { list: nil }, types)).to eq Util.bin_to_hex(expected)
      expect(Util.bin_to_hex Eip712.encode_data("List", { list: [] }, types)).to eq Util.bin_to_hex(expected)
    end

    it "raises for an invalid array type or a wrong fixed length" do
      invalid = { Bad: [{ name: "list", type: "uint7[]" }] }
      expect { Eip712.encode_data("Bad", { list: [] }, invalid) }.to raise_error Abi::Type::ParseError, "Integer size out of bounds"
      expect { Eip712.encode_data("Bad", { list: [1] }, invalid) }.to raise_error Abi::Type::ParseError, "Integer size out of bounds"
      pair = { Pair: [{ name: "pair", type: "uint256[2]" }] }
      expect { Eip712.encode_data("Pair", { pair: [1, 2, 3] }, pair) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
    end

    # Encodes a struct whose only member `f` has the given array type.
    def encode_box(type, value)
      Eip712.encode_data("Box", { f: value }, { Person: person, Box: [{ name: "f", type: type }] })
    end

    # An array field with two faults raises one error: the type and its sizes
    # first, then a wrong fixed length, then the elements, the order chosen
    # in #420.
    it "raises an invalid type or size before a wrong fixed length" do
      aggregate_failures do
        expect { encode_box("uint7[2]", [1, 2, 3]) }.to raise_error Abi::Type::ParseError, "Integer size out of bounds"
        expect { encode_box("Person[x][2]", [[], [], []]) }.to raise_error Abi::Type::ParseError, "Invalid type format"
      end
    end

    it "raises a wrong fixed length before any invalid element, atomic or hashed" do
      wallet = message_data[:from][:wallet].to_s
      bad_cow = { name: "Cow", wallet: "0xzz" }
      cow_data = message_data[:from]
      aggregate_failures do
        expect { encode_box("uint256[2]", [2 ** 256, 1, 2]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("address[2]", ["0xzz", wallet, wallet]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("bytes[2]", ["0xzz", "0x01", "0x02"]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("string[2]", [5, "a", "b"]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("Person[2]", [bad_cow, cow_data, cow_data]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
      end
    end

    it "raises a wrong outer length before the errors of a nested array" do
      bad_cow = { name: "Cow", wallet: "0xzz" }
      aggregate_failures do
        expect { encode_box("uint256[3][2]", [[1, 2], [1, 2, 3], [1, 2, 3]]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("uint256[2][2]", [[2 ** 256, 1], [1, 2], [1, 2]]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("string[2][2]", [["a", "b"], [5, "c"], ["d", "e"]]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
        expect { encode_box("Person[1][2]", [[bad_cow], [], []]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"

        # a nested array checks its own length before its elements, too
        expect { encode_box("uint256[2][]", [[2 ** 256, 1, 2]]) }.to raise_error Abi::EncodingError, "Expecting 2 elements: 3 provided"
      end
    end

    # Before #420 every struct array raised; struct arrays now take the ABI
    # type parser's rule for dimensions, so a non-numeric size still raises.
    it "rejects a struct array with a non-numeric size, as before #420" do
      aggregate_failures do
        expect { encode_box("Person[x]", []) }.to raise_error Abi::Type::ParseError, "Invalid type format"
        expect { encode_box("Person[x]", [message_data[:from]]) }.to raise_error Abi::Type::ParseError, "Invalid type format"
        expect { encode_box("Person[x][]", []) }.to raise_error Abi::Type::ParseError, "Invalid type format"
        expect { encode_box("Person[1x]", []) }.to raise_error Abi::Type::ParseError, "Invalid type format"
        expect { encode_box("Person[-1]", []) }.to raise_error Abi::Type::ParseError, "Invalid type format"
      end
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

  describe "binary bytesN starting with 0x or 0X" do
    # encode_data passes keccak256(contents) to Abi.encode as a bytes32; for
    # these two it starts with the bytes of "0x" and "0X".
    subject(:contents) { ["Hello, Bob! 161461", "Hello, Bob! 62425"] }

    # The EIP-712 hash of the Mail example with other contents, built from the
    # reference example's published domain separator, Mail typeHash and
    # Person hashes (see ".hash_type" and ".hash_data").
    def typed_data_hash(text)
      domain_separator = Util.hex_to_bin "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
      type_hash = Util.hex_to_bin "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
      from = Util.hex_to_bin "fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8"
      to = Util.hex_to_bin "cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1"
      struct_hash = Util.keccak256 type_hash + from + to + Util.keccak256(text)
      Util.keccak256 "\x19\x01" + domain_separator + struct_hash
    end

    it "hashes a string field whose keccak256 starts with 0x or 0X" do
      expect(typed_data_hash "Hello, Bob!").to eq Util.hex_to_bin "0xbe609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
      expect(contents.map { |text| Util.bin_to_hex(Util.keccak256 text)[0, 4] }).to eq ["3078", "3058"]
      contents.each do |text|
        data = typed_data.merge(message: message_data.merge(contents: text))
        expect(Eip712.hash data).to eq typed_data_hash(text)
      end
    end

    it "signs typed data with such a field" do
      # ref https://github.com/ethereum/EIPs/blob/7f606a6e0e24bcf38d18e5a8cd9fbc71565f3257/assets/eip-712/Example.js#L126
      cow = Key.new priv: Util.keccak256("cow")
      contents.each do |text|
        data = typed_data.merge(message: message_data.merge(contents: text))
        signature = cow.sign_typed_data data
        expect(Signature.verify data, signature, cow.address).to be true
      end
    end
  end

  describe "typed data that is no Hash" do
    # Signature.verify takes an Array as typed data, and the typed-data methods
    # first run enforce_typed_data, which reads the data by Symbol keys.
    subject(:cow) { Key.new priv: Util.keccak256("cow") }
    subject(:signature) { cow.sign_typed_data typed_data }

    it "raises a typed-data error for an Array, a String, an Integer, a Symbol or a Struct" do
      record = Struct.new(:types, :primaryType, :domain, :message)
      [[1, 2], [typed_data], "text", 5, :types, record.new(*typed_data.values)].each do |data|
        error = "Data is not a Hash: #{data.class}."
        expect { Eip712.enforce_typed_data data }.to raise_error Eip712::TypedDataError, error
        expect { Eip712.hash data }.to raise_error Eip712::TypedDataError, error
        expect { cow.sign_typed_data data }.to raise_error Eip712::TypedDataError, error
        expect { Signature.recover_typed_data data, signature }.to raise_error Eip712::TypedDataError, error
      end
      [[1, 2], [typed_data]].each do |data|
        expect { Signature.verify data, signature, cow.address }.to raise_error Eip712::TypedDataError, "Data is not a Hash: Array."
      end
    end

    it "raises the missing-data error for nil and empty data, as before" do
      [nil, [], {}].each do |data|
        expect { Eip712.hash data }.to raise_error Eip712::TypedDataError, "Data is missing, try again with data."
      end
      [[], {}].each do |data|
        expect { Signature.verify data, signature, cow.address }.to raise_error Eip712::TypedDataError, "Data is missing, try again with data."
      end
    end

    it "hashes, signs and recovers a Hash subclass and a delegator to the Hash" do
      # ref https://github.com/ethereum/EIPs/blob/7f606a6e0e24bcf38d18e5a8cd9fbc71565f3257/assets/eip-712/Example.js#L126
      digest = Util.hex_to_bin "0xbe609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
      published = "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"
      [Class.new(Hash).new.merge!(typed_data), SimpleDelegator.new(typed_data)].each do |data|
        expect(Eip712.hash data).to eq digest
        expect(cow.sign_typed_data data).to eq published
        expect(Signature.recover_typed_data data, published).to eq cow.public_hex
      end
    end
  end

  describe "typed data with a schema of the wrong shape" do
    # enforce_typed_data checks the shape of the schema, its members, type
    # definitions and field entries, but not the field values.
    def with_person(fields)
      typed_data.merge(types: types.merge(Person: fields))
    end

    it "raises a typed-data error for a member of another class" do
      [
        [{ types: 5 }, "Data types are not a Hash: Integer."],
        [{ types: [1] }, "Data types are not a Hash: Array."],
        [{ primaryType: 5 }, "Data primaryType is not a String or Symbol: Integer."],
        [{ primaryType: ["Mail"] }, "Data primaryType is not a String or Symbol: Array."],
        [{ domain: 5 }, "Data domain is not a Hash: Integer."],
        [{ domain: "text" }, "Data domain is not a Hash: String."],
        [{ message: 5 }, "Data message is not a Hash: Integer."],
        [{ message: [1] }, "Data message is not a Hash: Array."],
      ].each do |member, error|
        expect { Eip712.hash typed_data.merge(member) }.to raise_error Eip712::TypedDataError, error
      end
    end

    it "raises a typed-data error for a type definition that is no list of fields, used or not" do
      [[5, "Integer"], ["string name", "String"], [{ name: "name", type: "string" }, "Hash"]].each do |fields, name|
        expect { Eip712.hash with_person(fields) }.to raise_error Eip712::TypedDataError, "Data type Person is not a list of fields: #{name}."
      end
      domain = typed_data.merge(types: types.merge(EIP712Domain: 5))
      expect { Eip712.hash domain }.to raise_error Eip712::TypedDataError, "Data type EIP712Domain is not a list of fields: Integer."
      unused = typed_data.merge(types: types.merge(Unused: 5))
      expect { Eip712.hash unused }.to raise_error Eip712::TypedDataError, "Data type Unused is not a list of fields: Integer."
    end

    it "raises a typed-data error for a field entry of another shape" do
      [
        [5, "a field that is not a Hash: Integer."],
        [["name", "string"], "a field that is not a Hash: Array."],
        [{ type: "string" }, "a field name that is not a String or Symbol: NilClass."],
        [{ name: 5, type: "string" }, "a field name that is not a String or Symbol: Integer."],
        [{ "name" => "name", "type" => "string" }, "a field name that is not a String or Symbol: NilClass."],
        [{ name: "name" }, "a field type that is not a String or Symbol: NilClass."],
        [{ name: "name", type: 5 }, "a field type that is not a String or Symbol: Integer."],
      ].each do |field, error|
        expect { Eip712.hash with_person([field]) }.to raise_error Eip712::TypedDataError, "Data type Person has #{error}"
      end
    end

    it "hashes a Set of fields, Symbol field names and delegators as before" do
      # ref https://github.com/ethereum/EIPs/blob/7f606a6e0e24bcf38d18e5a8cd9fbc71565f3257/assets/eip-712/Example.js
      digest = Util.hex_to_bin "0xbe609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
      symbol_names = person.map { |field| field.merge(name: field[:name].to_sym) }
      delegated_names = person.map { |field| field.merge(name: SimpleDelegator.new(field[:name])) }

      # Mail's field types, Person and string, but not the ABI types, which
      # the ABI type parser takes as Strings only
      delegated_types = mail.map { |field| field.merge(type: SimpleDelegator.new(field[:type])) }
      [
        with_person(Set[*person]),
        with_person(symbol_names),
        with_person(delegated_names),
        typed_data.merge(types: types.merge(Mail: delegated_types)),
        typed_data.merge(primaryType: SimpleDelegator.new("Mail")),
        typed_data.merge(domain: SimpleDelegator.new(domain_data)),
      ].each do |data|
        expect(Eip712.hash data).to eq digest
      end
    end

    it "raises for a missing member before a member of another class, as before" do
      expect { Eip712.hash typed_data.merge(domain: 5, message: nil) }.to raise_error Eip712::TypedDataError, "Data message is missing."
      no_domain_type = typed_data.merge(types: types.reject { |name, _| name == :EIP712Domain }, domain: 5)
      expect { Eip712.hash no_domain_type }.to raise_error Eip712::TypedDataError, "Data EIP712Domain is missing."
    end

    it "raises an ABI type error for an atomic field type that is a Symbol, as before" do
      fields = mail.map { |field| field[:name] == "contents" ? field.merge(type: :string) : field }
      expect { Eip712.hash typed_data.merge(types: types.merge(Mail: fields)) }.to raise_error Abi::Type::ParseError, "Invalid type format"
    end
  end

  describe "type names that are Symbols" do
    # A Symbol names the same type as its String: EIP-712 has type names as
    # strings, and the type lookups read either.
    subject(:cow) { Key.new priv: Util.keccak256("cow") }
    subject(:digest) { "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2" }

    it "encodes and hashes a Symbol primary type like its String" do
      # ref https://github.com/ethereum/EIPs/blob/7f606a6e0e24bcf38d18e5a8cd9fbc71565f3257/assets/eip-712/Example.js
      expect(Eip712.encode_type :Person, types).to eq "Person(string name,address wallet)"
      expect(Eip712.encode_type :Mail, types).to eq "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
      expect(Util.bin_to_hex Eip712.hash_type :Mail, types).to eq "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
      expect(Eip712.encode_data :Mail, message_data, types).to eq Util.hex_to_bin "0xa0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8"
      expect(Util.bin_to_hex Eip712.hash_data :Mail, message_data, types).to eq "c52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e"
      expect(Util.bin_to_hex Eip712.hash_data :Person, message_data[:from], types).to eq "fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8"
      expect(Util.bin_to_hex Eip712.hash_data :EIP712Domain, domain_data, types).to eq "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
    end

    it "hashes, signs and recovers typed data with a Symbol primaryType" do
      # ref https://github.com/ethereum/EIPs/blob/7f606a6e0e24bcf38d18e5a8cd9fbc71565f3257/assets/eip-712/Example.js#L126
      data = typed_data.merge(primaryType: :Mail)
      published = "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"
      expect(Util.bin_to_hex Eip712.hash(data)).to eq digest
      expect(cow.sign_typed_data data).to eq published
      expect(Signature.recover_typed_data data, published).to eq cow.public_hex
    end

    it "hashes struct field types that are Symbols like their Strings" do
      # from and to as :Person, then only from
      symbols = mail.map { |field| field[:type] == "Person" ? field.merge(type: :Person) : field }
      [symbols, [symbols[0], mail[1], mail[2]]].each do |fields|
        expect(Util.bin_to_hex Eip712.hash(typed_data.merge(types: types.merge(Mail: fields)))).to eq digest
      end
    end
  end
end
