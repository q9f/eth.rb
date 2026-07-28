<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Domain 06 — Contracts, ENS & Solidity

As-built API contract for the high-level application layer: the smart-contract
wrapper (ABI → callable objects, custom-error decoding), ENS name resolution,
and the `solc` binding.

**Scope:** `Eth::Contract` (+ `Event`, `Function`, `FunctionInput`,
`FunctionOutput`, `Initializer`, `Error`), `Eth::Ens` (+ `Resolver`,
`CoinType`), `Eth::Solidity`.
**Source:** `lib/eth/contract.rb`, `lib/eth/contract/`, `lib/eth/ens.rb`,
`lib/eth/ens/`, `lib/eth/solidity.rb`.
**Parent spec:** [../../SPEC.md](../../SPEC.md) — register R1, R4, R10, R11.
**Standards:** Solidity ABI, ERC-20/721/1155, ERC-6093 custom errors, EIP-1271,
EIP-137/2304 ENS, SLIP-44 coin types.

---

## Eth::Contract

`class Eth::Contract` — a contract wrapper that builds a per-contract anonymous
class delegating to the parent instance. Uses `forwardable`,
`Eth::{Abi,Util,Address,Solidity}`, `keccak`, JSON.

- **Attributes:** `attr_reader :address`; `attr_accessor :key`,
  `:gas_limit, :gas_price, :max_fee_per_gas, :max_priority_fee_per_gas, :nonce`,
  `:bin, :name, :abi, :class_object`, `:events, :functions,
  :constructor_inputs, :errors`.
- `initialize(name, bin, abi)` — up-cases the first letter of `name`; prefer the
  factories.
- **Factories:** `self.from_file(file:, contract_index: 0)` (compiles via
  `Initializer`/`Solidity`; `ArgumentError` on a missing file or no contracts),
  `self.from_abi(abi:, address:, name:)`, `self.from_bin(bin:, abi:, name:)`
  (both accept a JSON string or an Array).
- `address=(addr)` — accepts a `String` or `Eth::Address`, checksums, and
  propagates to events.
- `function(name, args: nil)` / `error(name, args: nil)` — look up by name (and
  arity); raise `ArgumentError, "this function does not exist!"` /
  `"this error does not exist!"`.
- `decode_error(rpc_error)` → `"execution reverted: Name(args)"` for a known
  custom error (matched on the 4-byte selector), the decoded string for the
  standard `Error(string)` selector `0x08c379a0`, else the raw RPC message.
- `build` — creates the delegator class under `Eth::Contract` via `Forwardable`
  (`remove_const` + `const_set`, so redefinition is silent).

### Nested classes

- **`Contract::Function`** — `attr_accessor :name, :inputs, :outputs,
  :signature, :constant, :function_string`; `initialize(data)`;
  `self.calc_signature(name, inputs)`; `self.encoded_function_signature(signature)`
  (4-byte keccak hex, unprefixed); `encode_call(*args)` (`0x` + selector + ABI
  args, **or the `"0" * 64` filler when arg encoding is empty — R4**);
  `decode_call_result(data)` (`nil` for `"0x"`).
- **`Contract::Event`** — `initialize(data)`; `name`, `input_types`, `inputs`,
  `event_string`, `signature` (`Digest::Keccak.hexdigest(event_string, 256)`),
  `address`/`set_address`, `decode_params(topics, data = "0x")` → `Hash` of
  name → value (indexed from topics, non-indexed from data). *(R10: the YARD
  `@return` names an ActiveSupport type; the gem returns a plain string-keyed
  Hash and has no ActiveSupport dependency.)*
- **`Contract::Error`** — `attr_accessor :name, :inputs, :signature,
  :error_string`; `self.calc_signature`, `self.encoded_error_signature`
  (`0x`-prefixed), `decode(data)`.
- **`Contract::FunctionInput` / `FunctionOutput`** — identical shape:
  `attr_accessor :type, :raw_type, :name`; `initialize(data)` (parses via
  `Abi::Type.parse`); `type` (reconstructed string), `parsed_type`.
- **`Contract::Initializer`** — `attr_accessor :contracts, :file`;
  `initialize(file)` (compiles with `Eth::Solidity`); `build_all`.

**R10 (docs-gap):** none of the `attr_*` declarations in the `Contract` family
carry doc comments — the largest hole in the repo's 100% documentation claim.

## Eth::Ens

`module Eth::Ens` — `DEFAULT_ADDRESS = Address.new("0x00000000000C2E074eC69A0d
Fb2997BA6C7d2e1e")` (the canonical ENS registry).

### Eth::Ens::CoinType

`BITCOIN 0`, `LITECOIN 2`, `DOGECOIN 3`, `ETHEREUM 60`, `ETHEREUM_CLASSIC 61`,
`ROOTSTOCK 137`, `BITCOIN_CASH 145`, `BINANCE 714` (SLIP-44).

### Eth::Ens::Resolver

`class Eth::Ens::Resolver` — `attr_accessor :client, :registry`.

- `initialize(client, address = DEFAULT_ADDRESS)` — builds the
  `ENSRegistryWithFallback` contract from
  `File.read(File.join(File.dirname(__FILE__), "../../../abi/ens_registry.json"))`.
- `owner(ens_name)`, `resolver(ens_name)` (loads `../../../abi/ens_resolver.json`
  as `ENSPublicResolver`).
- `resolve(ens_name, coin_type = CoinType::ETHEREUM)` — `ETHEREUM` → `addr(node)`;
  `ETHEREUM_CLASSIC` → `addr(node, coinType)`; otherwise
  `NotImplementedError, "Coin type #{coin_type} not implemented!"`.
- `text(ens_name, key = "description")`.
- `namehash(ens_name)` (keccak fold over reversed labels).
- `normalize(input)` — `ArgumentError` on blacklisted characters, else
  downcase. **R11:** documented as UTS-46/tr46 normalization but implements only
  an ASCII blacklist + downcase (no punycode/unicode).

**R1:** the ABI JSONs live in the repo's `abi/` directory and are loaded here by
a source-relative path — the gemspec's `require_paths = ["lib", "abis"]` names a
non-existent `abis/` directory and is stale dead configuration (shipping still
works because `git ls-files` includes `abi/*.json`).

## Eth::Solidity

`class Eth::Solidity` — thin binding to a system `solc`. Uses `open3`, JSON.

- **Error:** `CompilerError < StandardError`.
- `attr_reader :compiler`.
- `initialize(path = nil)` — searches `PATH` for `solc` (honors `PATHEXT`);
  `SystemCallError` if not found.
- `compile(contract)` → `{ "Name" => { "abi" => …, "bin" => … } }`; invokes
  `solc --optimize --via-ir --combined-json=bin,abi <realpath>`;
  `Errno::ENOENT, "Contract file not found: …"` on a missing file;
  `CompilerError` (with stderr) on a failed compile. `--via-ir` is always on.

---

## Cross-references

- `Contract` is consumed by `Client` (domain 05) for deploy/call/transact and
  custom-error decoding; `Contract::Function`/`Event`/`Error` wrap `Eth::Abi`
  (domain 03).
- `Ens::Resolver` is reached through `Client#resolve_ens` (domain 05).
- `Solidity` backs `Contract.from_file` and the `solc`-dependent specs
  (verification Tier 1).
- Register items: **R1** (dead `abis/` require-path), **R4** (`encode_call`
  filler), **R10** (undocumented `attr_*`), **R11** (ENS `normalize`). See
  [../../SPEC.md](../../SPEC.md) §9.
