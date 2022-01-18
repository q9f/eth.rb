require "spec_helper"

describe Key::Decrypter do
  def read_key_fixture(path)
    File.read "./spec/fixtures/keys/#{path}.json"
  end

  describe ".perform pbkdf2 key" do
    let(:password) { "testpassword" }
    let(:key_data) { read_key_fixture password }

    it "recovers the example pbkdf2 key" do
      result = Key::Decrypter.perform key_data, password
      expect(result.private_hex).to eq("7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d")
    end

    it "detects authentication code mismatch" do
      # update mac key to create mismatch
      data = JSON.parse key_data
      data["crypto"]["mac"] = "12345"
      expect {
        Key::Decrypter.perform JSON.dump(data), password
      }.to raise_error Key::Decrypter::DecrypterError, "Message Authentications Codes do not match!"
    end
  end

  describe ".perform scrypt key" do
    let(:password) { "testingtesting" }
    let(:key_data) { read_key_fixture password }

    it "recovers the example scrypt key" do
      result = Key::Decrypter.perform key_data, password
      expect(result.private_hex).to eq("61a59f570abf5145971648acec6edc5f61487a9b570ca9c4e4c9f2d8e356b9af")
    end
  end

  describe "detects unknown key derivation functions" do
    let(:password) { "testunknownkdf" }
    let(:key_data) { read_key_fixture password }

    it "detects unknown key derivation functions" do
      expect {
        Key::Decrypter.perform key_data, password
      }.to raise_error Key::Decrypter::DecrypterError, "Unsupported key derivation function: nosuchalgorithm!"
    end
  end

  context "official ethereum test fixtures" do

    # load official ethereum/tests fixtures for key stores
    let(:basic_keystore_tests_file) { File.read "spec/fixtures/ethereum/tests/KeyStoreTests/basic_tests.json" }
    subject(:basic_keystore_tests) { JSON.parse basic_keystore_tests_file }

    it "can decrypt the test cases" do
      basic_keystore_tests.each do |test|
        key_store = test[1]["json"]
        password = test[1]["password"]
        priv = Key.new priv: test[1]["priv"]
        decrypted = Key::Decrypter.perform key_store, password
        expect(decrypted.private_hex).to eq priv.private_hex
      end
    end
  end
end
