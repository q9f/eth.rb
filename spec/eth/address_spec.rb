require "spec_helper"

describe Address do
  describe ".initialize" do
    # alice is initialized with an unprefixed address
    subject(:alice) { Address.new "c1c0f155bd054597c60cb33e6da7edbc9c70275b" }
    # bob is initialized with a prefixed address
    subject(:bob) { Address.new "0x7291d3cd257053bac810ee2c55fd7c154bd455af" }

    it "generates functional addresses" do
      # generates a functional key for alice of type Address
      expect(alice).to be_an_instance_of Address
      expect(bob).to be_an_instance_of Address

      # ensure both addresses are not the same
      expect(alice.address).not_to eq bob.address
    end

    it "prefixes an unprefixed address" do
      # ensure both addresses contains the 0x prefix
      # alice's address was initialized without 0x
      expect(alice.address).to start_with "0x"
      expect(bob.address).to start_with "0x"
    end
  end

  describe ".valid?" do
    context "given an address with a valid checksum" do
      let(:addresses) do
        [
          "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
          "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
          "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
          "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
        ]
      end

      it "returns true" do
        addresses.each do |address|
          expect(Address.new address).to be_valid
        end
      end
    end

    context "given an address with an invalid checksum" do
      let(:addresses) do
        [
          "0x5AAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
          "0xFB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
          "0xDbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
          "0xd1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
        ]
      end

      it "raises" do
        addresses.each do |address|
          expect {
            Address.new address
          }.to raise_error Address::CheckSumError
        end
      end
    end

    context "given an address with all uppercase letters" do
      let(:addresses) do
        [
          "0x5AAEB6053F3E94C9B9A09F33669435E7EF1BEAED",
          "0xFB6916095CA1DF60BB79CE92CE3EA74C37C5D359",
          "0xDBF03B407C01E7CD3CBEA99509D93F8DDDC8C6FB",
          "0xD1220A0CF47C7B9BE7A2E6BA89F429762E7B9ADB",
          # common EIP55 examples
          "0x52908400098527886E0F7030069857D2E4169EE7",
          "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
        ]
      end

      it "returns true" do
        addresses.each do |address|
          expect(Address.new address).to be_valid
        end
      end
    end

    context "given an address with all lowercase letters" do
      let(:addresses) do
        [
          "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed",
          "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359",
          "0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb",
          "0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb",
          # common EIP55 examples
          "0xde709f2102306220921060314715629080e2fb77",
          "0x27b1fdb04752bbc536007a920d24acb045561c26",
        ]
      end

      it "returns true" do
        addresses.each do |address|
          expect(Address.new address).to be_valid
        end
      end
    end

    context "given an invalid address" do
      let(:addresses) do
        [
          "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beae",
          "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359d",
          "0x5AAEB6053F3E94C9B9A09F33669435E7EF1BEAE",
          "0xFB6916095CA1DF60BB79CE92CE3EA74C37C5D359D",
        ]
      end

      it "raises" do
        addresses.each do |address|
          expect {
            Address.new address
          }.to raise_error Address::CheckSumError
        end

        expect { Address.new "foo" }.to raise_error Address::CheckSumError, "Unknown address type foo!"
      end
    end
  end

  describe ".zero?" do
    let(:zero) { Address::ZERO }
    let(:addresses) do
      [
        "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed",
        "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359",
        "0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb",
        "0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb",
      ]
    end

    it "returns true for the zero address" do
      expect(Address.new(zero)).to be_zero
    end

    it "returns false for a valid address" do
      addresses.each do |address|
        expect(Address.new(address)).not_to be_zero
      end
    end
  end

  describe ".checksummed" do
    let(:addresses) do
      [
        # downcased
        ["0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed", "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"],
        ["0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359", "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"],
        ["0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb", "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"],
        ["0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb", "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"],
        # upcased
        ["0x5AAEB6053F3E94C9B9A09F33669435E7EF1BEAED", "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"],
        ["0xFB6916095CA1DF60BB79CE92CE3EA74C37C5D359", "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"],
        ["0xDBF03B407C01E7CD3CBEA99509D93F8DDDC8C6FB", "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"],
        ["0xD1220A0CF47C7B9BE7A2E6BA89F429762E7B9ADB", "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"],
        # checksummed
        ["0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed", "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"],
        ["0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359", "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"],
        ["0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB", "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"],
        ["0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb", "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"],
      ]
    end

    it "follows EIP55 standard" do
      addresses.each do |plain, checksummed|
        address = Address.new(plain)
        expect(address.checksummed).to eq checksummed
      end
    end

    context "given an invalid address" do
      let(:bad) { "0x#{SecureRandom.hex(21)[0..40]}" }

      it "raises an error" do
        expect {
          Address.new(bad).checksummed
        }.to raise_error Address::CheckSumError
      end
    end
  end
end
