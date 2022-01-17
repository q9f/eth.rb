require "spec_helper"

# These test vectors are specified in the ethereum wiki:
# https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition

describe Key::Encrypter do
  describe ".perform" do
    let(:password) { "testpassword" }
    let(:key) { Key.new priv: "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d" }
    let(:uuid) { "3198bc9c-6672-5ab3-d995-4942343ae5b6" }

    context "pbkdf2 test vector" do
      let(:iv) { "6087dab2f9fdbbfaddc31a909735c1e6" }
      let(:salt) { "ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd" }
      let(:options) do
        {
          iv: iv,
          salt: salt,
          id: uuid,
        }
      end

      it "recovers the key using pbkdf2" do
        result = Key::Encrypter.perform key, password, options
        json = JSON.parse result

        expect(json["crypto"]["cipher"]).to eq("aes-128-ctr")
        expect(json["crypto"]["cipherparams"]["iv"]).to eq(iv)
        expect(json["crypto"]["ciphertext"]).to eq("5318b4d5bcd28de64ee5559e671353e16f075ecae9f99c7a79a38af5f869aa46")
        expect(json["crypto"]["kdf"]).to eq("pbkdf2")
        expect(json["crypto"]["kdfparams"]["c"]).to eq(262_144)
        expect(json["crypto"]["kdfparams"]["dklen"]).to eq(32)
        expect(json["crypto"]["kdfparams"]["prf"]).to eq("hmac-sha256")
        expect(json["crypto"]["kdfparams"]["salt"]).to eq(salt)
        expect(json["crypto"]["mac"]).to eq("517ead924a9d0dc3124507e3393d175ce3ff7c1e96529c6c555ce9e51205e9b2")
        expect(json["id"]).to eq(uuid)
        expect(json["version"]).to eq(3)
      end

      it "uses generated iv and salt to encrypt" do
        # pass an empty dict for the options param
        result = Key::Encrypter.perform key, password, {}
        json = JSON.parse result

        expect(json["crypto"]["cipherparams"]["iv"]).not_to be_empty
        expect(json["crypto"]["kdfparams"]["salt"]).not_to be_empty
      end

      describe "detects unknown key derivation functions" do
        let(:bad_options) do
          {
            iv: iv,
            salt: salt,
            id: uuid,
            kdf: "badfunction", # this function is not supported
          }
        end

        it "detects unknown key derivation functions" do
          expect {
            Key::Encrypter.perform key, password, bad_options
          }.to raise_error Key::Encrypter::EncrypterError, "Unsupported key derivation function: badfunction!"
        end
      end
    end

    context "scrypt test vector" do
      let(:iv) { "83dbcc02d8ccb40e466191a123791e0e" }
      let(:salt) { "ab0c7876052600dd703518d6fc3fe8984592145b591fc8fb5c6d43190334ba19" }
      let(:options) do
        {
          kdf: "scrypt",
          iv: iv,
          salt: salt,
          id: uuid,
        }
      end

      it "recovers the key using scrypt" do
        result = Key::Encrypter.perform key, password, options
        json = JSON.parse result

        expect(json["crypto"]["cipher"]).to eq("aes-128-ctr")
        expect(json["crypto"]["cipherparams"]["iv"]).to eq(iv)
        expect(json["crypto"]["ciphertext"]).to eq("d172bf743a674da9cdad04534d56926ef8358534d458fffccd4e6ad2fbde479c")
        expect(json["crypto"]["kdf"]).to eq("scrypt")
        expect(json["crypto"]["kdfparams"]["n"]).to eq(262_144)
        expect(json["crypto"]["kdfparams"]["dklen"]).to eq(32)
        expect(json["crypto"]["kdfparams"]["p"]).to eq(8)
        expect(json["crypto"]["kdfparams"]["r"]).to eq(1)
        expect(json["crypto"]["kdfparams"]["salt"]).to eq(salt)
        expect(json["crypto"]["mac"]).to eq("2103ac29920d71da29f15d75b4a16dbe95cfd7ff8faea1056c33131d846e3097")
        expect(json["id"]).to eq(uuid)
        expect(json["version"]).to eq(3)
      end
    end
  end
end
