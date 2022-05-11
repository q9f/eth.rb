# Ethereum for Ruby

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/q9f/eth.rb/Spec)](https://github.com/q9f/eth.rb/actions)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/q9f/eth.rb)](https://github.com/q9f/eth.rb/releases)
[![Gem](https://img.shields.io/gem/v/eth)](https://rubygems.org/gems/eth)
[![Gem](https://img.shields.io/gem/dt/eth)](https://rubygems.org/gems/eth)
[![Visitors](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fq9f%2Feth.rb&count_bg=%2379C83D&title_bg=%23555555&icon=rubygems.svg&icon_color=%23FF0000&title=visitors&edge_flat=false)](https://hits.seeyoufarm.com)
[![codecov](https://codecov.io/gh/q9f/eth.rb/branch/main/graph/badge.svg?token=IK7USBPBZY)](https://codecov.io/gh/q9f/eth.rb)
[![Maintainability](https://api.codeclimate.com/v1/badges/469e6f66425198ad7614/maintainability)](https://codeclimate.com/github/q9f/eth.rb/maintainability)
[![Top Language](https://img.shields.io/github/languages/top/q9f/eth.rb?color=red)](https://github.com/q9f/eth.rb/pulse)
[![Yard Doc API](https://img.shields.io/badge/documentation-API-blue)](https://q9f.github.io/eth.rb)
[![Usage Wiki](https://img.shields.io/badge/usage-WIKI-blue)](https://github.com/q9f/eth.rb/wiki)
[![Open-Source License](https://img.shields.io/github/license/q9f/eth.rb)](LICENSE)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/q9f/eth.rb/issues)

A straightforward library to build, sign, and broadcast Ethereum transactions. It allows the separation of key and node management. Sign transactions and handle keys anywhere you can run Ruby and broadcast transactions through any local or remote node. Sign messages and recover signatures for authentication.

What you get:
- [x] Secp256k1 Key-Pairs and Encrypted Ethereum Key-Stores (JSON)
- [x] EIP-55 Checksummed Ethereum Addresses
- [x] EIP-155 Replay protection with Chain IDs (with presets)
- [x] EIP-191 Ethereum Signed Messages (with prefix and type)
- [x] EIP-712 Ethereum Signed Type Data
- [x] EIP-1271 Smart-Contract Authentification
- [x] EIP-1559 Ethereum Type-2 Transactions (with priority fee and max gas fee)
- [x] EIP-2028 Call-data intrinsic gas cost estimates (plus access lists)
- [x] EIP-2718 Ethereum Transaction Envelopes (and types)
- [x] EIP-2930 Ethereum Type-1 Transactions (with access lists)
- [x] ABI-Encoder and Decoder (including type parser)
- [x] RLP-Encoder and Decoder (including sedes)
- [x] RPC-Client (IPC/HTTP) for Execution-Layer APIs
- [x] Solidity bindings (compile contracts from Ruby)
- [x] Full smart-contract support (deploy, transact, and call)

Contents:
- [1. Installation](#1-installation)
- [2. Usage](#2-usage)
  - [2.1. Ethereum Keys and Addresses (EIP-55)](#21-ethereum-keys-and-addresses-eip-55)
  - [2.2. Ethereum Signatures (EIP-191, EIP-712)](#22-ethereum-signatures-eip-191-eip-712)
  - [2.3. Ethereum Chains (EIP-155)](#23-ethereum-chains-eip-155)
  - [2.4. Ethereum Transactions (EIP-1559, EIP-2718, EIP-2930)](#24-ethereum-transactions-eip-1559-eip-2718-eip-2930)
  - [2.5. Ethereum ABI Encoder and Decoder](#25-ethereum-abi-encoder-and-decoder)
  - [2.6. Ethereum RLP Encoder and Decoder](#26-ethereum-rlp-encoder-and-decoder)
  - [2.7. Ethereum RPC-Client](#27-ethereum-rpc-client)
  - [2.8. Solidity Compiler Bindings](#28-solidity-compiler-bindings)
  - [2.9. Interact with Smart Contract](#29-interact-with-smart-contract)
- [3. Documentation](#3-documentation)
- [4. Testing](#4-testing)
- [5. Contributing](#5-contributing)
- [6. License and Credits](#6-license-and-credits)

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
Check out
[![Yard Doc API](https://img.shields.io/badge/documentation-API-blue)](https://q9f.github.io/eth.rb)
and
[![Usage Wiki](https://img.shields.io/badge/usage-WIKI-blue)](https://github.com/q9f/eth.rb/wiki)
for full details.

### 2.1. Ethereum Keys and Addresses (EIP-55)
Generate a random Secp256k1 key-pair.

```ruby
key = Eth::Key.new
# => #<Eth::Key:0x00005574a6ba80b8 @private_key=#<Secp256k1::PrivateKey:0x00005574a6b9a0a8 @data=")&\x86P\xB5\x16\xD9]\xFA;\x1F\xF6\xD9\xCF\xE3Vj/\xE2\x81\xC0\x9D\xE9\x05o!q\x82G\x9A\x10Q">, @public_key=#<Secp256k1::PublicKey:0x00005574a6b9bf98>>
```

Create an password-encrypted Ethereum key-store.

```ruby
my_key = Eth::Key.new priv: "30137644b564785d01420f8043f043d74dcca64008e57c59f8ce713a0005a54b"
key_store = Eth::Key::Encrypter.perform my_key, "secret-password-1337"
# => "{\"crypto\":{\"cipher\":\"aes-128-ctr\",\"cipherparams\":{\"iv\":\"7e5c0fe1e27f4ea61b0f4427dd63555f\"},\"ciphertext\":\"6353653bba494cdae6bcd510febc980cdc6f7b23cfbdf950d7a909a69625c8fd\",\"kdf\":\"pbkdf2\",\"kdfparams\":{\"c\":262144,\"dklen\":32,\"prf\":\"hmac-sha256\",\"salt\":\"cce96286f3c32267fc91f756365307fe6a4c83b6b2a73c69535f721fa407736c\"},\"mac\":\"3361ffd2b158a1d7bca5a5fd86a251ba3e9d80b602c867a2e0f47023a0e17a57\"},\"id\":\"642ee9fc-72e4-4d0a-902f-247c0b59bfda\",\"version\":3}"
restored_key = Eth::Key::Decrypter.perform key_store, "secret-password-1337"
# => "30137644b564785d01420f8043f043d74dcca64008e57c59f8ce713a0005a54b"
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

See `/spec` or [Documentation](https://q9f.github.io/eth.rb/) for more details about key-pairs, encrypting/decrypting key-stores with a secret, and checksummed addresses.

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
recovered_key = Eth::Signature.personal_recover "Hello World!", signature, Eth::Chain::GOERLI
# => "04b45200621c013a5fbab999ac33b0c836328a04afa0255ffbe6ea0f6fd97e187b02199886d942a9f50f7e279a2bc74c93b2afcbd7255489939f9b36a5eae5e281"
Eth::Util.public_key_to_address(recovered_key).to_s
# => "0xD496b23D61F88A8C7758fca7560dCFac7b3b01F9"
Eth::Signature.verify "Hello World!", signature, address, Eth::Chain::GOERLI
# => true
```

See `/spec` or [Documentation](https://q9f.github.io/eth.rb/) for signing typed data as per EIP-712.

### 2.3. Ethereum Chains (EIP-155)
Manage Ethereum chain IDs for EIP-155 replay protection.

```ruby
chain_id = Eth::Chain::OPTIMISM
# => 10
v = Eth::Chain.to_v 0, Eth::Chain::OPTIMISM
# => 55
recovery_id = Eth::Chain.to_recovery_id v, Eth::Chain::OPTIMISM
# => 0
chain_id = Eth::Chain.to_chain_id v
# => 10
```

### 2.4. Ethereum Transactions (EIP-1559, EIP-2718, EIP-2930)
Create an EIP-1559-conform transaction:

```ruby
payload = {
  chain_id: Eth::Chain::GOERLI,
  nonce: 5,
  priority_fee: 3 * Eth::Unit::GWEI,
  max_gas_fee: 69 * Eth::Unit::GWEI,
  gas_limit: 230_420,
  to: "0xCaA29806044A08E533963b2e573C1230A2cd9a2d",
  value: 0.069423 * Eth::Unit::ETHER,
}
# => {:chain_id=>5, :nonce=>5, :priority_fee=>0.3e10, :max_gas_fee=>0.69e11, :gas_limit=>230420, :to=>"0xCaA29806044A08E533963b2e573C1230A2cd9a2d", :value=>0.69423e17}
tx = Eth::Tx.new payload
# => #<Eth::Tx::Eip1559:0x0000557e35fc5a68 @access_list=[], @amount=69423000000000000, @chain_id=5, @destination="CaA29806044A08E533963b2e573C1230A2cd9a2d", @gas_limit=230420, @max_fee_per_gas=69000000000, @max_priority_fee_per_gas=3000000000, @payload="", @sender="", @signature_r=0, @signature_s=0, @signature_y_parity=nil, @signer_nonce=5, @type=2>
my_key = Eth::Key.new priv: "30137644b564785d01420f8043f043d74dcca64008e57c59f8ce713a0005a54b"
# => #<Eth::Key:0x0000557e36243178 @private_key=#<Secp256k1::PrivateKey:0x0000557e36242d40 @data="0\x13vD\xB5dx]\x01B\x0F\x80C\xF0C\xD7M\xCC\xA6@\b\xE5|Y\xF8\xCEq:\x00\x05\xA5K">, @public_key=#<Secp256k1::PublicKey:0x0000557e36242cf0>>
tx.sign my_key
# => "cba302c0ebf8d0205a78ae97f560419b407e32e2426f416abc95a9bfc9dac09c"
tx.hex
# => "02f873050584b2d05e00851010b872008303841494caa29806044a08e533963b2e573c1230a2cd9a2d87f6a3d9c63df00080c080a03aa187d10b138d3e0155729adb961cd89e10f988ba2d19d6869770b9e5a23d10a04d40864600136ae214916043c7d63b849c98db757e95c86983a036982816e1af"
```

This gem also supports access lists and ABI-encoded data payloads. See `/spec` or [Documentation](https://q9f.github.io/eth.rb/) for more details about the various supported transaction types (legacy, type-1, type-2), payload parameters, and how to estimate intrinsic gas costs.

### 2.5. Ethereum ABI Encoder and Decoder
Encode and decode Ethereum application binary interface data (ABI).

```ruby
Eth::Util.bin_to_hex Eth::Abi.encode(["string", "address"], ["Hello, Bob!", "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"])
# => "0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000d496b23d61f88a8c7758fca7560dcfac7b3b01f9000000000000000000000000000000000000000000000000000000000000000b48656c6c6f2c20426f6221000000000000000000000000000000000000000000"
Eth::Abi.decode(["string", "address"], "0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000d496b23d61f88a8c7758fca7560dcfac7b3b01f9000000000000000000000000000000000000000000000000000000000000000b48656c6c6f2c20426f6221000000000000000000000000000000000000000000")
# => ["Hello, Bob!", "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"]
```

### 2.6. Ethereum RLP Encoder and Decoder
Serialize and deserialize Ethereum recursive-length prefix data (RLP).

```ruby
Eth::Util.bin_to_hex Eth::Rlp.encode ["Hello, Bob!", "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"]
# => "f78b48656c6c6f2c20426f6221aa307864343936623233643631663838613863373735386663613735363064636661633762336230316639"
Eth::Rlp.decode "f78b48656c6c6f2c20426f6221aa307864343936623233643631663838613863373735386663613735363064636661633762336230316639"
# => ["Hello, Bob!", "0xd496b23d61f88a8c7758fca7560dcfac7b3b01f9"]
```

Or ;-)

```ruby
Eth::Rlp.decode "c7c0c1c0c3c0c1c0"
# => [[], [[]], [[], [[]]]]
```

### 2.7. Ethereum RPC-Client
Create an IPC- or HTTP-RPC-API client to seamlessly query the chain state, e.g., Infura over HTTPS with access token:

```ruby
infura = Eth::Client.create "https://mainnet.infura.io/v3/#{access_token}"
# => #<Eth::Client::Http:0x000055d43f3ca460 @gas_limit=21000, @host="mainnet.infura.io", @id=0, @max_fee_per_gas=0.2e11, @max_priority_fee_per_gas=0, @port=443, @ssl=true, @uri=#<URI::HTTPS https://mainnet.infura.io/v3/31b...d93>>
deposit_contract = Eth::Address.new "0x00000000219ab540356cBB839Cbe05303d7705Fa"
# => #<Eth::Address:0x000055d43f381738 @address="0x00000000219ab540356cBB839Cbe05303d7705Fa">
infura.get_balance deposit_contract
# => 9087314000069000000000069
```

Or set up a local development environment with `geth --dev`:

```ruby
cli = Eth::Client.create "/tmp/geth.ipc"
# => #<Eth::Client::Ipc:0x000055d43f51c390 @gas_limit=21000, @id=0, @max_fee_per_gas=0.2e11, @max_priority_fee_per_gas=0, @path="/tmp/geth.ipc">
cli.eth_coinbase
# => {"jsonrpc"=>"2.0", "id"=>1, "result"=>"0x6868074fb21c48dfad0c448fbabd99383a6598e4"}
tx = cli.transfer_and_wait(Eth::Key.new.address, 1337 * Eth::Unit::ETHER)
# => "0x141c6dff40df34fe4fce5a65588d2161dab3e0e977fb8049ff7d79bc901034f7"
cli.eth_get_transaction_by_hash tx
# => {"jsonrpc"=>"2.0", "id"=>8, "result"=> {"blockHash"=>"0x47e742038c75851348dbda87b15fde044d54c442c371f43bea881a44d5589de3", "blockNumber"=>"0x1", "from"=>"0x6868074fb21c48dfad0c448fbabd99383a6598e4", "gas"=>"0x5208", "gasPrice"=>"0x342770c1", "maxFeePerGas"=>"0x77359401", "maxPriorityFeePerGas"=>"0x1", "hash"=>"0x141c6dff40df34fe4fce5a65588d2161dab3e0e977fb8049ff7d79bc901034f7", "input"=>"0x", "nonce"=>"0x0", "to"=>"0x311c61e5dc6123ad016bb7fd687d283c327bcd5f", "transactionIndex"=>"0x0", "value"=>"0x487a9a304539440000", "type"=>"0x2", "accessList"=>[], "chainId"=>"0x539", "v"=>"0x0", "r"=>"0xb42477d69eae65a3a3d91d9cb173e4a45a403fb0a15fa729dbfdc9d13211d7b5", "s"=>"0x4a2f98fc2b61c2d7c907520bc8c6ebe42ea6fe1cb6824f95e4b30e9464395100"}}
cli.get_balance "0x311c61e5dc6123ad016bb7fd687d283c327bcd5f"
# => 1337000000000000000000
cli.get_nonce cli.eth_coinbase["result"]
# => 1
```

Check out `Eth::Api` for a list of supported RPC-APIs or consult the [Documentation](https://q9f.github.io/eth.rb/) for more details.

### 2.8. Solidity Compiler Bindings
Link a system-level Solidity compiler (`solc`) to your Ruby library and compile contracts.

```ruby
solc = Eth::Solidity.new
# => #<Eth::Solidity:0x000055f05040c6d0 @compiler="/usr/bin/solc">
contract = solc.compile "spec/fixtures/contracts/greeter.sol"
# => {"Greeter"=>
#   {"abi"=>
#     [{"inputs"=>[{"internalType"=>"string", "name"=>"message", "type"=>"string"}], "stateMutability"=>"nonpayable", "type"=>"constructor"},
#      {"inputs"=>[], "name"=>"greet", "outputs"=>[{"internalType"=>"string", "name"=>"", "type"=>"string"}], "stateMutability"=>"view", "type"=>"function"},
#      {"inputs"=>[], "name"=>"kill", "outputs"=>[], "stateMutability"=>"nonpayable", "type"=>"function"}],
#    "bin"=>
#     "6080604052348015...6c634300080c0033"},
#  "Mortal"=>
#   {"abi"=>[{"inputs"=>[], "stateMutability"=>"nonpayable", "type"=>"constructor"}, {"inputs"=>[], "name"=>"kill", "outputs"=>[], "stateMutability"=>"nonpayable", "type"=>"function"}],
#    "bin"=>
#     "6080604052348015...6c634300080c0033"}}
```

The `contract["Greeter"]["bin"]` could be directly used to deploy the contract as `Eth::Tx` payload. Check out the [Documentation](https://q9f.github.io/eth.rb/) for more details.

### 2.9. Interact with Smart Contract

Create, compile, and deploy smart contracts.

```ruby
contract = Eth::Contract.from_file(file: 'spec/fixtures/contracts/dummy.sol')
# => #<Eth::Contract::Dummy:0x00007fbeee936598>
cli = Eth::Client.create "/tmp/geth.ipc"
# => #<Eth::Client::Ipc:0x00007fbeee946128 @gas_limit=21000, @id=0, @max_fee_per_gas=0.2e11, @max_priority_fee_per_gas=0, @path="/tmp/geth.ipc">
address = cli.deploy_and_wait(contract)
# => "0x2f2faa160420cee087ded96bad52475147136bd8"
```

Transact with or call the deployed contract.

```ruby
cli.transact_and_wait(contract, "set", 1234)
# => "0x49ca4c0a5729da19a1d2574de9a444a9cd3219bdad81745b54f9cf3bb83b6a06"
cli.call(contract, "get")
# => 1234
```

Or call an existing contract, e.g., the ENS registry:

```ruby
ens_registry_abi = '[{"inputs":[{"internalType":"contract ENS","name":"_old","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"label","type":"bytes32"},{"indexed":false,"internalType":"address","name":"owner","type":"address"}],"name":"NewOwner","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"address","name":"resolver","type":"address"}],"name":"NewResolver","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"ttl","type":"uint64"}],"name":"NewTTL","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"node","type":"bytes32"},{"indexed":false,"internalType":"address","name":"owner","type":"address"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"old","outputs":[{"internalType":"contract ENS","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"recordExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"resolver","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"resolver","type":"address"},{"internalType":"uint64","name":"ttl","type":"uint64"}],"name":"setRecord","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"address","name":"resolver","type":"address"}],"name":"setResolver","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes32","name":"label","type":"bytes32"},{"internalType":"address","name":"owner","type":"address"}],"name":"setSubnodeOwner","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"bytes32","name":"label","type":"bytes32"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"resolver","type":"address"},{"internalType":"uint64","name":"ttl","type":"uint64"}],"name":"setSubnodeRecord","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"},{"internalType":"uint64","name":"ttl","type":"uint64"}],"name":"setTTL","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"node","type":"bytes32"}],"name":"ttl","outputs":[{"internalType":"uint64","name":"","type":"uint64"}],"payable":false,"stateMutability":"view","type":"function"}]'
ens_registry_address = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"
ens_registry_name = "ENSRegistryWithFallback"
ens_registry = Eth::Contract.from_abi(name: ens_registry_name, address: ens_registry_address, abi: ens_registry_abi)
# => #<Eth::Contract::ENSRegistryWithFallback:0x000055bece570980>
ens_registry.address
# => "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"
cli.call(ens_registry, "old")
# => "0x112234455c3a32fd11230c42e7bccd4a84e02010"
```

The gem also comes with an EIP-1271 smart-contract authentification interface.

```ruby
cli.is_valid_signature contract, hash, signature
# => true
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
The test suite expects working local HTTP and IPC endpoints with a prefunded developer account, e.g.:

```shell
geth --dev --http --ipcpath /tmp/geth.ipc &
```

To run tests, simply use `rspec`. Note, that the Ethereum test fixtures are also required.

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

It is not only a rewrite of the `eth` gem but also a partial merge of the `ethereum` gem by Marek Kirejczyk and Yuta Kurotaki.
* https://github.com/EthWorks/ethereum.rb (MIT)

This gem also includes a revised version of the ABI gem by Jan Xie and Zhang Yaning.
* https://github.com/cryptape/ruby-ethereum-abi (MIT)

It also contains a condensed version of the RLP gem by Jan Xie and Zhang Yaning.
* https://github.com/cryptape/ruby-rlp (MIT)
