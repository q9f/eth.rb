#!/usr/bin/env ruby

# Do not load the installed gem, rather load the source code from this repo
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'eth'
print "Ruby Ethereum Examples\n"
print "======================\n"
print "\n"

# Create a random key-pair (Eth::Key)
key_pair = Eth::Key.new
print "Secp256k1 Pirvate key\t#{key_pair.private_hex}\n"
print "Secp256k1 Public key \t#{key_pair.public_hex}\n"
print "\n"

# Create an Eth address (Eth::Address)
address = key_pair.address
print "ETH Address (EIP-55) \t#{address.checksummed}\n"
print "ETH Address valid?   \t#{address.valid?}\n"
print "\n"

# Manage Chains (Eth::Chains)
chain_id = Eth::Chains::GOERLI # EIP 155
print "Chain ID (Goerli)    \t#{chain_id}\n"
print "\n"

# Sign messages (Eth::Key)
message = "Hello World!"
signature = key_pair.personal_sign message, chain_id
print "Message to sign      \t\"#{message}\"\n"
print "Signature            \t#{signature}\n"

# Verify messages (Eth::Signature)
recovered_pubkey = Eth::Signature.personal_recover message, signature, chain_id
recovered_address = Eth::Utils.public_key_to_address recovered_pubkey
signature_verifies = Eth::Signature.verify message, signature, key_pair.address, chain_id
print "Recovered public key \t\"#{recovered_pubkey}\"\n"
print "Recovered address    \t\"#{recovered_address}\"\n"
print "Signature matches?   \t\"#{signature_verifies}\"\n"
