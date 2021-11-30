require 'spec_helper'

describe Eth::Key do
  it "generates functional keypairs" do

    # generates a functional key for alice of type Eth::Key
    alice = Eth::Key.new
    expect(alice).to be_an_instance_of Eth::Key

    # generates a functional key for bob of type Eth::Key
    bob = Eth::Key.new
    expect(bob).to be_an_instance_of Eth::Key

    # ensure both keys are not the same
    expect(alice.private_key).not_to eq(bob.private_key)
    expect(alice.private_hex).not_to eq(bob.private_hex)
    expect(alice.private_bytes).not_to eq(bob.private_bytes)
    expect(alice.public_key).not_to eq(bob.public_key)
    expect(alice.public_hex).not_to eq(bob.public_hex)
    expect(alice.public_hex_compressed).not_to eq(bob.public_hex_compressed)
    expect(alice.public_bytes).not_to eq(bob.public_bytes)
    expect(alice.public_bytes_compressed).not_to eq(bob.public_bytes_compressed)
  end

  it "restores keypairs from existing private keys" do

    # generates a functional key for alice
    alice = Eth::Key.new

    # creates a backup of alice's keypair
    backup = Eth::Key.new priv: alice.private_key.data

    # ensure both keys are the same
    expect(alice.private_key).to eq(backup.private_key)
    expect(alice.private_hex).to eq(backup.private_hex)
    expect(alice.private_bytes).to eq(backup.private_bytes)
    expect(alice.public_key).to eq(backup.public_key)
    expect(alice.public_hex).to eq(backup.public_hex)
    expect(alice.public_hex_compressed).to eq(backup.public_hex_compressed)
    expect(alice.public_bytes).to eq(backup.public_bytes)
    expect(alice.public_bytes_compressed).to eq(backup.public_bytes_compressed)
  end
end
