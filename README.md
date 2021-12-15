# Eth for Ruby
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/q9f/eth.rb/Spec)](https://github.com/q9f/eth.rb/actions)
[![Yard Doc API](https://img.shields.io/badge/docs-100%25-blue)](https://q9f.github.io/eth.rb)
[![codecov](https://codecov.io/gh/q9f/eth.rb/branch/main/graph/badge.svg?token=IK7USBPBZY)](https://codecov.io/gh/q9f/eth.rb)
[![Maintainability](https://api.codeclimate.com/v1/badges/469e6f66425198ad7614/maintainability)](https://codeclimate.com/github/q9f/eth.rb/maintainability)
[![GitHub top language](https://img.shields.io/github/languages/top/q9f/eth.rb?color=red)](https://github.com/q9f/eth.rb/pulse)
[![GitHub](https://img.shields.io/github/license/q9f/eth.rb)](LICENSE)

<!--
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/q9f/eth.rb)](https://github.com/q9f/eth.rb/releases)
[![Gem](https://img.shields.io/gem/v/eth)](https://rubygems.org/gems/eth)
[![Gem](https://img.shields.io/gem/dt/eth)](https://rubygems.org/gems/eth)
-->

A simple library to build and sign Ethereum transactions. Allows separation of key and node management. Sign transactions and handle keys anywhere you can run ruby, broadcast transactions through any node. Sign messages and recover signatures for authentication.

### Work in progress
_This is a partial rewrite of the old `eth` gem by Steve Ellis._
* https://github.com/se3000/ruby-eth/

### What works?

##### `Eth::Key`

Managing Secp256k1 public-private keypairs to sign messages in EIP-191 format.

```ruby
key = Eth::Key.new
key = Eth::Key.new priv: "268be6f4a68c40f6862b7ac9aed8f701dc25a95ddb9a44d8b1f520b75f440a9a"
key.public_hex
# => "04b45200621c013a5fbab999ac33b0c836328a04afa0255ffbe6ea0f6fd97e187b02199886d942a9f50f7e279a2bc74c93b2afcbd7255489939f9b36a5eae5e281"
key.address.to_s
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
key.personal_sign "Hello World!" # EIP 191
# => "ac6a59417d8688c8144f01a662384fa691636b48a071d4b7c13902bb87ca472b0bce1d7a758f39a5759ed5e937ce61f50dd1b83158371f8d0faeb9b7d81c194225"
```

##### `Eth::Address`

Managing Ethereum address objects adhering to EIP-55 checksum format.

```ruby
address = Eth::Address.new "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"
address.valid?
# => true
address.checksummed # EIP 55
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
```

##### `Eth::Chains`

Managing Ethereum chain IDs for EIP-155 replay protection.

```ruby
chain_id = Eth::Chains::OPTIMISM # EIP 155
# => 10
v = Eth::Chains.to_v 0, Eth::Chains::OPTIMISM
# => 55
recovery_id = Eth::Chains.to_recovery_id v, Eth::Chains::OPTIMISM
# => 0
```

##### `Eth::Signature`

Recovering and verifying personal signatures respecting EIP 155 and 191.

```ruby
address = Eth::Address.new "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"
signature = "ac6a59417d8688c8144f01a662384fa691636b48a071d4b7c13902bb87ca472b0bce1d7a758f39a5759ed5e937ce61f50dd1b83158371f8d0faeb9b7d81c19422d"
recovered_key = Eth::Signature.personal_recover "Hello World!", signature, Eth::Chains::GOERLI
# => "04b45200621c013a5fbab999ac33b0c836328a04afa0255ffbe6ea0f6fd97e187b02199886d942a9f50f7e279a2bc74c93b2afcbd7255489939f9b36a5eae5e281"
Eth::Utils.public_key_to_address(recovered_key).to_s
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
Eth::Signature.verify "Hello World!", signature, address, Eth::Chains::GOERLI
# => true
```
