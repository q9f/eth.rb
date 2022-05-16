# Change Log
All notable changes to this project will be documented in this file.

## [0.5.4]
### Added
- Eth/client: method for eip-1271 ([#80](https://github.com/q9f/eth.rb/pull/80))

### Changed
- Docs: update changelog ([#77](https://github.com/q9f/eth.rb/pull/77))
- Gem: bump version to 0.5.4 ([#78](https://github.com/q9f/eth.rb/pull/78))
- Ci: bump ruby version to 3.1 on ci ([#79](https://github.com/q9f/eth.rb/pull/79))
- Fix typos ([#81](https://github.com/q9f/eth.rb/pull/81))
- Eth/contract: allow creating from file, abi, bin ([#83](https://github.com/q9f/eth.rb/pull/83))
- Eth/client: fix account requirement for client.call() ([#85](https://github.com/q9f/eth.rb/pull/85))
- Add dependency support for openssl 2.2 and greater, including 3.x ([#88](https://github.com/q9f/eth.rb/pull/88))

## [0.5.3]
### Added
- Smart contract support ([#68](https://github.com/q9f/eth.rb/pull/68))

### Changed
- Eth/abi: decode event log ([#69](https://github.com/q9f/eth.rb/pull/69))
- Gem: bump version ([#70](https://github.com/q9f/eth.rb/pull/70))
- Eth/abi/event: batch log decoder ([#71](https://github.com/q9f/eth.rb/pull/71))

## [0.5.2]
### Added
- Eth/solidity: add solidity compiler bindings ([#66](https://github.com/q9f/eth.rb/pull/66))

### Changed
- Eth: remove duplicated code ([#62](https://github.com/q9f/eth.rb/pull/62))
- Ci: allow coverage to drop to 99% without failing ([#63](https://github.com/q9f/eth.rb/pull/63))
- Docs: update readme ([#64](https://github.com/q9f/eth.rb/pull/64))
- Docs: add wiki to readme ([#65](https://github.com/q9f/eth.rb/pull/65))

## [0.5.1]
### Added
- Add eth::rlp module ([#52](https://github.com/q9f/eth.rb/pull/52))
- Eth/client: implement http/ipc ([#37](https://github.com/q9f/eth.rb/pull/37))

### Changed
- Docs: update changelog ([#61](https://github.com/q9f/eth.rb/pull/61))
- Eth/chain: add sepolia chain id; docs ([#60](https://github.com/q9f/eth.rb/pull/60))
- Eth/rlp: cleanup ([#59](https://github.com/q9f/eth.rb/pull/59))
- Eth/tx: properly serialize signatures ([#58](https://github.com/q9f/eth.rb/pull/58))
- Eth/client: fix legacy transfer ([#57](https://github.com/q9f/eth.rb/pull/57))
- Gem: relax openssl requirement ([#56](https://github.com/q9f/eth.rb/pull/56))
- Docs: update changelog ([#53](https://github.com/q9f/eth.rb/pull/53))
- Spec: add upstream test fixtures for keystore ([#50](https://github.com/q9f/eth.rb/pull/50))

## [0.5.0]
### Added
- Eth/tx: create legacy, type-1, and type-2 transactions [#33](https://github.com/q9f/eth.rb/pull/33)
- Signature: implement eip 712 typed structured data signing [#27](https://github.com/q9f/eth.rb/pull/27)
- Lib: import ABI to eth/abi [#29](https://github.com/q9f/eth.rb/pull/29)
- Eth/chains: implement eip 155 for replay protection [#20](https://github.com/q9f/eth.rb/pull/20)

### Changed
- Docs: update readme with features [#49](https://github.com/q9f/eth.rb/pull/49)
- Eth/tx: add method to estimate intrinsic gas costs [#48](https://github.com/q9f/eth.rb/pull/48)
- Eth/key: allow chain_id empty for signing messages/data [#47](https://github.com/q9f/eth.rb/pull/47)
- Gem: prepare for release [#46](https://github.com/q9f/eth.rb/pull/46)
- Eth/sig: allow v values > 0xff, fix #30 [#43](https://github.com/q9f/eth.rb/pull/43)
- Eth/abi: refactor for maintainability [#42](https://github.com/q9f/eth.rb/pull/42)
- Docs: improve readme [#41](https://github.com/q9f/eth.rb/pull/41)
- Lib: improve error handling [#39](https://github.com/q9f/eth.rb/pull/39)
- Docs: update readme for tx and keys [#40](https://github.com/q9f/eth.rb/pull/40)
- Implement encrypt/decrypt [#22](https://github.com/q9f/eth.rb/pull/22)
- Gem: clean up some docs and scripts [#32](https://github.com/q9f/eth.rb/pull/32)
- Rename util and chain to singular [#26](https://github.com/q9f/eth.rb/pull/26)
- Docs: add some examples to readme [#25](https://github.com/q9f/eth.rb/pull/25)
- Key/signature: personal sign and verify [#24](https://github.com/q9f/eth.rb/pull/24)
- Ci: only run coverage on CI [#23](https://github.com/q9f/eth.rb/pull/23)
- Lib/signature: implement personal_recover (eip 191 [#21](https://github.com/q9f/eth.rb/pull/21)
- Eth/util: public_key_to_address should return an eth::address [#19](https://github.com/q9f/eth.rb/pull/19)
- Ci: add docs workflow [#18](https://github.com/q9f/eth.rb/pull/18)
- Address class implementation and tests [#13](https://github.com/q9f/eth.rb/pull/13)
- Spec: improve util tests [#12](https://github.com/q9f/eth.rb/pull/12)
- Spec: improve key tests [#11](https://github.com/q9f/eth.rb/pull/11)
- Gems: bump keccak and secp256k1 [#10](https://github.com/q9f/eth.rb/pull/10)
- Docs: add code climate badge [#8](https://github.com/q9f/eth.rb/pull/8)
- Ci: enable codecov [#7](https://github.com/q9f/eth.rb/pull/7)
- Docs: add AUTHORS file [#6](https://github.com/q9f/eth.rb/pull/6)
- Lib: implement Eth::Key class [#4](https://github.com/q9f/eth.rb/pull/4)
- Ci: add nightly schedule [#2](https://github.com/q9f/eth.rb/pull/2)
- Reset gem to point blank [#1](https://github.com/q9f/eth.rb/pull/1)

## [0.4.18]
### Changed
- CI: add yard doc and rufo workflows [se3000/ruby-eth#75](https://github.com/se3000/ruby-eth/pull/75)
- Gem: run rufo [se3000/ruby-eth#74](https://github.com/se3000/ruby-eth/pull/74)
- Gem: dependencies [se3000/ruby-eth#73](https://github.com/se3000/ruby-eth/pull/73)
- Lib: fix compatibility with libressl (macos) and openssl 1.1.1k [se3000/ruby-eth#66](https://github.com/se3000/ruby-eth/pull/66)

## [0.4.17]
### Changed
- Gems: bump version to 0.4.17 [se3000/ruby-eth#70](https://github.com/se3000/ruby-eth/pull/70)
- Gems: bump keccak to 1.3.0 [se3000/ruby-eth#69](https://github.com/se3000/ruby-eth/pull/69)

## [0.4.16]
### Changed
- Docs: update changelog [se3000/ruby-eth#65](https://github.com/se3000/ruby-eth/pull/65)
- Gems: bump version to 0.4.16 [se3000/ruby-eth#65](https://github.com/se3000/ruby-eth/pull/65)
- License: update copyright notice [se3000/ruby-eth#64](https://github.com/se3000/ruby-eth/pull/64)
- Docs: add badges to readme [se3000/ruby-eth#64](https://github.com/se3000/ruby-eth/pull/64)
- Git: deprecating master [se3000/ruby-eth#63](https://github.com/se3000/ruby-eth/pull/63)
- CI: replace travis with github actions [se3000/ruby-eth#62](https://github.com/se3000/ruby-eth/pull/62)
- Gems: replace digest-sha3-patched with keccak [se3000/ruby-eth#58](https://github.com/se3000/ruby-eth/pull/58)

## [0.4.13], [0.4.14], [0.4.15]
_Released as [`eth-patched`](https://github.com/q9f/ruby-eth) from a different source tree._

## [0.4.12]
### Changed
- Bump rake version because of security vulnerability

## [0.4.11]
### Added
- Support for recovering signatures with a V value below 27 (like from Ledger hardware wallets)

## [0.4.10]
### Changed
- Use updated sha3 dependency
- Improved OpenSSL support

### Changed
- Changed Eth::Configuration.default_chain_id back to .chain_id for dependent libraries.

## [0.4.9]
### Changed
- [escoffon](https://github.com/escoffon) added support for chain IDs larger than 120.

## [0.4.8]
### Added
- [@buhrmi](https://github.com/buhrmi) added Eth::Key#personal_sign.
- [@buhrmi](https://github.com/buhrmi) added Eth::Key#personal_recover.

## [0.4.7]
### Changed
- Updated MoneyTree dependency.

## [0.4.6]
### Added
- Support scrypt private key decryption

## [0.4.5]
### Changed
- Further improve Open SSL configurability

## [0.4.4]
### Changed
- Support old versions of SSL to help avoid preious breaking changes

## [0.4.3]
### Added
- Eth::Key::Encrypter class to handle encrypting keys.
- Eth::Key.encrypt as a nice wrapper around Encrypter class.
- Eth::Key::Decrypter class to handle encrypting keys.
- Eth::Key.decrypt as a nice wrapper around Decrypter class.

## [0.4.2]
### Added
- Address#valid? to validate EIP55 checksums.
- Address#checksummed to generate EIP55 checksums.
- Utils.valid_address? to easily validate EIP55 checksums.
- Utils.format_address to easily convert an address to EIP55 checksummed.

### Changed
- Dependencies no longer include Ethereum::Base. Eth now implements those helpers directly and includes ffi, digest-sha3, and rlp directly.


## [0.4.1]
### Changed
- Tx#hash includes the '0x' hex prefix.

## [0.4.0]
### Added
- Tx#data_bin returns the data field of a transaction in binary.
- Tx#data_hex returns the data field of a transaction as a hexadecimal string.
- Tx#id is an alias of Tx#hash

### Changed
- Tx#data is configurable to return either hex or binary: `config.tx_data_hex = true`.
- Tx#hex includes the '0x' hex prefix.
- Key#address getter is prepended by '0x'.
- Extract public key to address method into Utils.public_key_to_address.
- Tx#from returns an address instead of a public key.
- Chain ID is updated to the later version of the spec.
