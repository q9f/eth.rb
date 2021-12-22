# Eth for Ruby

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/q9f/eth.rb/Spec)](https://github.com/q9f/eth.rb/actions)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/q9f/eth.rb)](https://github.com/q9f/eth.rb/releases)
[![Gem](https://img.shields.io/gem/v/eth)](https://rubygems.org/gems/eth)
[![Gem](https://img.shields.io/gem/dt/eth)](https://rubygems.org/gems/eth)
[![codecov](https://codecov.io/gh/q9f/eth.rb/branch/main/graph/badge.svg?token=IK7USBPBZY)](https://codecov.io/gh/q9f/eth.rb)
[![Maintainability](https://api.codeclimate.com/v1/badges/469e6f66425198ad7614/maintainability)](https://codeclimate.com/github/q9f/eth.rb/maintainability)
[![Yard Doc API](https://img.shields.io/badge/docs-API-blue)](https://q9f.github.io/eth.rb)
[![GitHub top language](https://img.shields.io/github/languages/top/q9f/eth.rb?color=red)](https://github.com/q9f/eth.rb/pulse)
[![GitHub](https://img.shields.io/github/license/q9f/eth.rb)](LICENSE)

- [1. Installation](#1-installation)
- [2. Usage](#2-usage)
  - [2.1. Ethereum Keys and Addresses (EIP-55)](#21-ethereum-keys-and-addresses-eip-55)
  - [2.2. Ethereum Signatures (EIP-191, EIP-712)](#22-ethereum-signatures-eip-191-eip-712)
  - [2.3. Ethereum Chains (EIP-155)](#23-ethereum-chains-eip-155)
  - [2.4. Ethereum Transactions (EIP-1559, EIP-2718)](#24-ethereum-transactions-eip-1559-eip-2718)
  - [2.5. Ethereum ABI Encoder and Decoder](#25-ethereum-abi-encoder-and-decoder)
- [3. Documentation](#3-documentation)
- [4. Testing](#4-testing)
- [5. Contributing](#5-contributing)
- [6. License and Credits](#6-license-and-credits)

A simple library to build and sign Ethereum transactions. Allows separation of key and node management. Sign transactions and handle keys anywhere you can run ruby, broadcast transactions through any node. Sign messages and recover signatures for authentication.

## 1. Installation

Add this line to your application's Gemfile:

```ruby
gem "eth"
```

Or install it yourself as:

```shell
gem install eth
```

## 2. Usage

### 2.1. Ethereum Keys and Addresses (EIP-55)

Generate a random Secp256k1 key-pair.

```ruby
key = Eth::Key.new
# => #<Eth::Key:0x00005574a6ba80b8 @private_key=#<Secp256k1::PrivateKey:0x00005574a6b9a0a8 @data=")&\x86P\xB5\x16\xD9]\xFA;\x1F\xF6\xD9\xCF\xE3Vj/\xE2\x81\xC0\x9D\xE9\x05o!q\x82G\x9A\x10Q">, @public_key=#<Secp256k1::PublicKey:0x00005574a6b9bf98>>
```

Manage Ethereum address objects adhering to EIP-55 checksum format.

```ruby
address = Eth::Address.new "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"
# => #<Eth::Address:0x00005574a6bd4fc8 @address="0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9">
address.valid?
# => true
address.checksummed # EIP 55
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
```

See `/spec` or [Documentation](https://q9f.github.io/eth.rb/) for encrypting/decrypting key-stores with a secret.

### 2.2. Ethereum Signatures (EIP-191, EIP-712)

Manage keypairs to sign messages in EIP-191 (`personal_sign`) format or typed data in EIP-712 (`sign_typed_data`) format.

```ruby
key = Eth::Key.new priv: "268be6f4a68c40f6862b7ac9aed8f701dc25a95ddb9a44d8b1f520b75f440a9a"
# => #<Eth::Key:0x00005574a699adc0 @private_key=#<Secp256k1::PrivateKey:0x00005574a6998200 @data="&\x8B\xE6\xF4\xA6\x8C@\xF6\x86+z\xC9\xAE\xD8\xF7\x01\xDC%\xA9]\xDB\x9AD\xD8\xB1\xF5 \xB7_D\n\x9A">, @public_key=#<Secp256k1::PublicKey:0x00005574a6998160>>
key.public_hex
# => "04b45200621c013a5fbab999ac33b0c836328a04afa0255ffbe6ea0f6fd97e187b02199886d942a9f50f7e279a2bc74c93b2afcbd7255489939f9b36a5eae5e281"
key.address.to_s
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
key.personal_sign "Hello World!"
# => "ac6a59417d8688c8144f01a662384fa691636b48a071d4b7c13902bb87ca472b0bce1d7a758f39a5759ed5e937ce61f50dd1b83158371f8d0faeb9b7d81c194225"
```

Recover and verify personal signatures respecting EIPs 155, 191, and 712.

```ruby
address = Eth::Address.new "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"
# => #<Eth::Address:0x00005574a6bd4fc8 @address="0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9">
signature = "ac6a59417d8688c8144f01a662384fa691636b48a071d4b7c13902bb87ca472b0bce1d7a758f39a5759ed5e937ce61f50dd1b83158371f8d0faeb9b7d81c19422d"
# => "ac6a59417d8688c8144f01a662384fa691636b48a071d4b7c13902bb87ca472b0bce1d7a758f39a5759ed5e937ce61f50dd1b83158371f8d0faeb9b7d81c19422d"
recovered_key = Eth::Signature.personal_recover "Hello World!", signature, Eth::Chains::GOERLI
# => "04b45200621c013a5fbab999ac33b0c836328a04afa0255ffbe6ea0f6fd97e187b02199886d942a9f50f7e279a2bc74c93b2afcbd7255489939f9b36a5eae5e281"
Eth::Utils.public_key_to_address(recovered_key).to_s
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
Eth::Signature.verify "Hello World!", signature, address, Eth::Chains::GOERLI
# => true
```

See `/spec` or [Documentation](https://q9f.github.io/eth.rb/) for signing typed data as per EIP-712.

### 2.3. Ethereum Chains (EIP-155)

Manage Ethereum chain IDs for EIP-155 replay protection.

```ruby
chain_id = Eth::Chains::OPTIMISM
# => 10
v = Eth::Chains.to_v 0, Eth::Chains::OPTIMISM
# => 55
recovery_id = Eth::Chains.to_recovery_id v, Eth::Chains::OPTIMISM
# => 0
```

### 2.4. Ethereum Transactions (EIP-1559, EIP-2718)

_Coming soon. [#17](https://github.com/q9f/eth.rb/issues/17)_

### 2.5. Ethereum ABI Encoder and Decoder

Encode and decode Ethereum application binary interface data (ABI).

```ruby
Eth::Util.bin_to_hex Eth::Abi.encode(["string", "address"], ["Hello, Bob!", "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"])
# => "0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000d496b23d61f88a8c7758fca7560dcfac7b3b01f9000000000000000000000000000000000000000000000000000000000000000b48656c6c6f2c20426f6221000000000000000000000000000000000000000000"
Eth::Abi.decode(["string", "address"], "0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000d496b23d61f88a8c7758fca7560dcfac7b3b01f9000000000000000000000000000000000000000000000000000000000000000b48656c6c6f2c20426f6221000000000000000000000000000000000000000000")
# => ["Hello, Bob!", "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"]
```

## 3. Documentation

The documentation can be found at: https://q9f.github.io/eth.rb

For any specific version, docs can be generated by `yard`:

```shell
gem install bundler rdoc yard
git checkout v0.5.0
yard doc
```

The goal is to have 100% API documentation available.

## 4. Testing

To run tests, simply use `rspec`. Note, that the Ethereum tests fixtures are required.

```shell
git submodule update --init --recursive
bundle install
rspec
```

The goal is to have 100% specification coverage for all code inside this gem.

## 5. Contributing

Pull requests are welcome! To contribute, please consider the following:
* Code should be fully documented. Run `yard doc` and make sure it does not yield any warnings or undocumented sets.
* Code should be fully covered by tests. Run `rspec` to make sure all tests pass. The CI has an integration that will assis you to identify uncovered lines of code and get coverage up to 100%.
* Code should be formatted properly. Try to eliminate the most common issues such as trailing white-spaces or duplicate new-lines. Usage of the `rufo` gem is recommended.
* Submit pull requests, questions, or issues to Github: https://github.com/q9f/eth.rb

## 6. License and Credits
The `eth` gem is licensed under the conditions of [Apache 2.0](./LICENSE.txt). Please see [AUTHORS](./AUTHORS.txt) for contributors and copyright notices.

This gem is a complete rewrite of the old `eth` gem by Steve Ellis.
* https://github.com/se3000/ruby-eth/ (MIT)

It also contains a revised version the ABI gem by Jan Xie and Zhang Yaning.
* https://github.com/cryptape/ruby-ethereum-abi (MIT)
