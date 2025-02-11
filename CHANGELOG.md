# Change Log
All notable changes to this project will be documented in this file.

## [0.5.13]
### Changed
* Eth/api: update to latest available go-ethereum apis [#301](https://github.com/q9f/eth.rb/pull/301)
* Eth/chain: update ids [#300](https://github.com/q9f/eth.rb/pull/300)
* Spec: update ethereum/tests fixtures [#303](https://github.com/q9f/eth.rb/pull/303)
* Ci: fix codecov uploader [#302](https://github.com/q9f/eth.rb/pull/302)
* Eth/tx: only enforce block gas limit on mainnet [#299](https://github.com/q9f/eth.rb/pull/299)
* Eth/util: fix single-byte hex-string nibbles [#298](https://github.com/q9f/eth.rb/pull/298)
* Eth/address: rename null address to zero address [#297](https://github.com/q9f/eth.rb/pull/297)
* Eth/address: add support to check for the ethereum "null address" [#296](https://github.com/q9f/eth.rb/pull/296)
* Build(deps): bump codecov/codecov-action from 4 to 5 [#295](https://github.com/q9f/eth.rb/pull/295)
* Build(deps): bump JamesIves/github-pages-deploy-action [#294](https://github.com/q9f/eth.rb/pull/294)
* Build(deps): bump JamesIves/github-pages-deploy-action [#288](https://github.com/q9f/eth.rb/pull/288)
* Eth/client: always return hash even if transaction didn't succeed [#284](https://github.com/q9f/eth.rb/pull/284)
* Eth/chain: update list of chains [#283](https://github.com/q9f/eth.rb/pull/283)
* Fix undefined method `raise_error' for an instance of Eth::Tx::Eip1559 (NoMethodError) [#282](https://github.com/q9f/eth.rb/pull/282)
* Gem: bump version to 0.5.13 [#281](https://github.com/q9f/eth.rb/pull/281)

## [0.5.12]
### Added
* Allow to call JSON RPC with custom block number [#268](https://github.com/q9f/eth.rb/pull/268)
* Support tuple params in EventLog [#276](https://github.com/q9f/eth.rb/pull/276)

### Changed
* Eth: update version [#280](https://github.com/q9f/eth.rb/pull/280)
* Eth/abi: fix negative integer coding [#279](https://github.com/q9f/eth.rb/pull/279)
* Support negative number from JSON RPC [#267](https://github.com/q9f/eth.rb/pull/267)
* Abi/event: confirm decoding tuples works [#278](https://github.com/q9f/eth.rb/pull/278)
* Allow to call JSON RPC with custom block number [#268](https://github.com/q9f/eth.rb/pull/268)
* Gem: run rufo [#277](https://github.com/q9f/eth.rb/pull/277)
* Fix event signature [#250](https://github.com/q9f/eth.rb/pull/250)
* Support tuple params in EventLog [#276](https://github.com/q9f/eth.rb/pull/276)
* Ci: update ruby version [#271](https://github.com/q9f/eth.rb/pull/271)
* Eth/api: remove coinbase as default account [#269](https://github.com/q9f/eth.rb/pull/269)
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.5.0 to 4.6.1 [#275](https://github.com/q9f/eth.rb/pull/275)
* Build(deps): bump github/codeql-action from 2 to 3 [#257](https://github.com/q9f/eth.rb/pull/257)
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.4.3 to 4.5.0 [#256](https://github.com/q9f/eth.rb/pull/256)
* Fix typo in contract_spec.rb [#253](https://github.com/q9f/eth.rb/pull/253)
* Eth/eip721: fix data type bug for bytes, fix #251 [#252](https://github.com/q9f/eth.rb/pull/252)
* Ci: unpatch geth [#248](https://github.com/q9f/eth.rb/pull/248)
* Build(deps): bump actions/checkout from 3 to 4 [#246](https://github.com/q9f/eth.rb/pull/246)

## [0.5.11]
### Added
* Eth/abi: allow encoding address types [#242](https://github.com/q9f/eth.rb/pull/242)
* Eth/solidity: enable --via-ir [#232](https://github.com/q9f/eth.rb/pull/232)
* Checking userinfo with the uri method [#233](https://github.com/q9f/eth.rb/pull/233)
* Eth/abi: add abicoder gem tests collection [#218](https://github.com/q9f/eth.rb/pull/218)
* Manual default_account [#215](https://github.com/q9f/eth.rb/pull/215)
* Add moonbeam networks in [#209](https://github.com/q9f/eth.rb/pull/209)

### Changed
* Spec: run rufo [#245](https://github.com/q9f/eth.rb/pull/245)
* Fix the decoding of unsigned transactions [#243](https://github.com/q9f/eth.rb/pull/243)
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.4.2 to 4.4.3 [#244](https://github.com/q9f/eth.rb/pull/244)
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.4.1 to 4.4.2 [#240](https://github.com/q9f/eth.rb/pull/240)
* Eth/tx: update tx initcode cost for shanghai [#237](https://github.com/q9f/eth.rb/pull/237)
* Eth/client: remove default gas limit attribute [#235](https://github.com/q9f/eth.rb/pull/235)
* Docs: minor fixups [#229](https://github.com/q9f/eth.rb/pull/229)
* Eth/contract: ensure contract name is title case [#228](https://github.com/q9f/eth.rb/pull/228)
* Deps: require forwardable for contracts [#227](https://github.com/q9f/eth.rb/pull/227)
* Ens/resolver: remove pending for etc coin type [#219](https://github.com/q9f/eth.rb/pull/219)
* Deps: update secp256k1 to 6 [#214](https://github.com/q9f/eth.rb/pull/214)
* Eth/solidity: add docs for solc path override [#213](https://github.com/q9f/eth.rb/pull/213)
* Manually overwrite solc path [#212](https://github.com/q9f/eth.rb/pull/212)
* Abi.decoder handles arrays of string and bytes [#207](https://github.com/q9f/eth.rb/pull/207)
* Eth/util: fix compressed public key to address in [#206](https://github.com/q9f/eth.rb/pull/206)
* Eth/api: update execution apis to latest spec [#204](https://github.com/q9f/eth.rb/pull/204)
* Eth/abi: split abi class into encoder and decoder [#203](https://github.com/q9f/eth.rb/pull/203)
* Eth/client: deduplicate code [#202](https://github.com/q9f/eth.rb/pull/202)
* Eth/client: rewrite send to send_request [#201](https://github.com/q9f/eth.rb/pull/201)
* Docs: update changelog for 0.5.10 [#200](https://github.com/q9f/eth.rb/pull/200)
* Tested with Ruby 3.2 [#199](https://github.com/q9f/eth.rb/pull/199)

## [0.5.10]
### Added
* Eth/client: add transfer_erc20 function [#197](https://github.com/q9f/eth.rb/pull/197)
* Eth/client: add resolve_ens function [#192](https://github.com/q9f/eth.rb/pull/192)

### Changed
* Eth/ens: restore docs for normalize [#198](https://github.com/q9f/eth.rb/pull/198)
* Docs: update readme [#195](https://github.com/q9f/eth.rb/pull/195)
* Eth/contract: ensure address arrays support [#194](https://github.com/q9f/eth.rb/pull/194)
* Eth/client: do not allow accessing local accounts on remote connections [#193](https://github.com/q9f/eth.rb/pull/193)
* Eth/client: correctly select functions [#191](https://github.com/q9f/eth.rb/pull/191)
* Docs: create security policy [#190](https://github.com/q9f/eth.rb/pull/190)
* Docs: add contribution guidelines [#189](https://github.com/q9f/eth.rb/pull/189)
* Docs: add coc [#188](https://github.com/q9f/eth.rb/pull/188)
* Docs: update changelog for 0.5.9 [#187](https://github.com/q9f/eth.rb/pull/187)

## [0.5.9]
### Added
* Eth/abi: dynamic struct encoding [#135](https://github.com/q9f/eth.rb/pull/135) [#185](https://github.com/q9f/eth.rb/pull/185)
* Eth/client: support camel case (convert before sending the tx) [#172](https://github.com/q9f/eth.rb/pull/172)
* Eth/client: add `tx_succeeded?` [#173](https://github.com/q9f/eth.rb/pull/173)

### Changed
* Eth/client: raise an error if a contract interaction reverts [#186](https://github.com/q9f/eth.rb/pull/186)
* Eth/client: dup params to prevent marshalling on client obj [#184](https://github.com/q9f/eth.rb/pull/184)
* Eth/client: add test for tx_succeeded? [#183](https://github.com/q9f/eth.rb/pull/183)
* Eth: rename functions prefixed with is_ [#182](https://github.com/q9f/eth.rb/pull/182)
* Eth/chain: update available chains [#181](https://github.com/q9f/eth.rb/pull/181)
* Docs: update changelog for 0.5.8 [#180](https://github.com/q9f/eth.rb/pull/180)
* Eth: happy new 2023 [#179](https://github.com/q9f/eth.rb/pull/179)
* Docs: fix readme workflow badge [#178](https://github.com/q9f/eth.rb/pull/178)
* Solidity: sanitize the contract path before compiling [#176](https://github.com/q9f/eth.rb/pull/176)
* Ci: add libyaml on ubuntu [#175](https://github.com/q9f/eth.rb/pull/175)

## [0.5.8]
### Added
* Client: ability to manual set nonce of tx for transfer, deploy, transact methods was added. [#169](https://github.com/q9f/eth.rb/pull/169)
* Client: ability for call contract methods with specific transaction value was added [#168](https://github.com/q9f/eth.rb/pull/168)
* Client: add ENS resolve support [#150](https://github.com/q9f/eth.rb/pull/150)

### Changed
* Client: satisfy yard docs for transfer kwargs [#170](https://github.com/q9f/eth.rb/pull/170)
* Client: remove invalid parameters from call_raw method [#166](https://github.com/q9f/eth.rb/pull/166)
* Gem: bump required ruby version to 3 [#165](https://github.com/q9f/eth.rb/pull/165)
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.4.0 to 4.4.1 [#162](https://github.com/q9f/eth.rb/pull/162)
* Gem: bump version to 0.5.8 [#161](https://github.com/q9f/eth.rb/pull/161)
* Docs: update changelog [#160](https://github.com/q9f/eth.rb/pull/160)

## [0.5.7]
### Added
* Eth/client: add http basic support auth ([#151](https://github.com/q9f/eth.rb/pull/151))
* Chore: add polygon chain test case ([#146](https://github.com/q9f/eth.rb/pull/146))

### Changed
* Docs: add readme header for yard ([#159](https://github.com/q9f/eth.rb/pull/159))
* Eth/client: fix api documentation ([#158](https://github.com/q9f/eth.rb/pull/158))
* Eth/client: update default fees ([#157](https://github.com/q9f/eth.rb/pull/157))
* Docs: move readme usage to wiki ([#156](https://github.com/q9f/eth.rb/pull/156))
* Eth/signature: fix allowing ledger v values of 0 ([#155](https://github.com/q9f/eth.rb/pull/155))
* Eth/client: rename http basic to http auth ([#154](https://github.com/q9f/eth.rb/pull/154))
* Fix Eth:Tx.decode for transaction with s length < 64 chars ([#148](https://github.com/q9f/eth.rb/pull/148))
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.3.4 to 4.4.0 ([#140](https://github.com/q9f/eth.rb/pull/140))
* Fixed to return uint256[] correctly when passed as type ([#147](https://github.com/q9f/eth.rb/pull/147))
* Build(deps): bump JamesIves/github-pages-deploy-action from 4.3.3 to 4.3.4 ([#133](https://github.com/q9f/eth.rb/pull/133))
* Docs: update CHANGELOG ([#132](https://github.com/q9f/eth.rb/pull/132))
* Gem: bump version to 0.5.7 ([#131](https://github.com/q9f/eth.rb/pull/131))

## [0.5.6]
### Added
- Eth/client: Add gas limit override option for contract deployments ([#128](https://github.com/q9f/eth.rb/pull/128))
- Eth/abi: support dynamic array encoding ([#122](https://github.com/q9f/eth.rb/pull/122))

### Changed
- Eth/client: Include contract constructor args when estimating intrinsic gas ([#111](https://github.com/q9f/eth.rb/pull/111))
- Eth/abi: allow parsing numerics from string inputs ([#112](https://github.com/q9f/eth.rb/pull/112))
- Eth/signature: fix prefix_message for multibyte characters ([#120](https://github.com/q9f/eth.rb/pull/120))
- Eth/abi: raise error if numeric comes as string ([#114](https://github.com/q9f/eth.rb/pull/114))
- Gem: bump version to 0.5.6 ([#130](https://github.com/q9f/eth.rb/pull/130))

## [0.5.5]
### Added
- Eth/contract: Add missing def_delegator for constructor_inputs ([#96](https://github.com/q9f/eth.rb/pull/96))
- Eth/client: Enable passing in constructor params to deploy ([#106](https://github.com/q9f/eth.rb/pull/106))
- Eth/chain: add matic/mumbai ([#107](https://github.com/q9f/eth.rb/pull/107))

### Changed
- Gem: bump version to 0.5.5 ([#89](https://github.com/q9f/eth.rb/pull/89))
- Docs: update changelog for 0.5.4 ([#90](https://github.com/q9f/eth.rb/pull/90))
- Ci: add weekly dependency checks ([#91](https://github.com/q9f/eth.rb/pull/91))
- Build(deps): bump github/codeql-action from 1 to 2 ([#92](https://github.com/q9f/eth.rb/pull/92))
- Build(deps): bump actions/checkout from 2 to 3 ([#93](https://github.com/q9f/eth.rb/pull/93))
- Build(deps): bump JamesIves/github-pages-deploy-action from 4.1.7 to 4.3.3 ([#94](https://github.com/q9f/eth.rb/pull/94))
- Eth/abi: fix handling of hex values for byte strings ([#100](https://github.com/q9f/eth.rb/pull/100))
- Eth/abi: add a testcase for handling hex and bin strings ([#101](https://github.com/q9f/eth.rb/pull/101))
- Eth/abi: Fix Eth::Abi::DecodingError in call method ([#105](https://github.com/q9f/eth.rb/pull/105))
- Eth: some docs and cleanups ([#108](https://github.com/q9f/eth.rb/pull/108))

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
