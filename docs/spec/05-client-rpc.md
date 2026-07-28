<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Domain 05 — Client & RPC

As-built API contract for the JSON-RPC client and its three transports. This is
the only part of the library that touches the network; it upholds the key/node
separation (SPEC I7): it never needs key material unless the caller passes
`sender_key`, and it contacts only caller-specified endpoints.

**Scope:** `Eth::Client` (+ `Http`, `Ipc`, `Ws`), `Eth::Api`.
**Source:** `lib/eth/client.rb`, `lib/eth/client/`, `lib/eth/api.rb`.
**Parent spec:** [../../SPEC.md](../../SPEC.md) — invariants I7, I12; register
R2, R5, R9, R12.
**EIPs referenced:** 1271 (signature checks), 1559 (fee semantics), 2304 (ENS
coin types).

---

## Eth::Client (base)

`class Eth::Client` — transport-agnostic convenience client. Uses
`Eth::{Tx,Address,Ens::Resolver,Abi,Util,Api}`.

- **Attributes:** `attr_reader :id, :chain_id`; `attr_accessor
  :default_account, :max_priority_fee_per_gas, :max_fee_per_gas, :block_number`
  (block tag for archive reads, default `"latest"`).
- **Errors:** `ContractExecutionError < StandardError`; `RpcError < IOError`
  with `attr_reader :data, :code` and `initialize(message, data = nil,
  code = nil)`.
- `self.create(host)` → `Client::Ipc` (host ends `.ipc`), `Client::Http`
  (starts `http`), or `Client::Ws` (starts `ws`); otherwise
  `ArgumentError, "Unable to detect client type!"`.
- `initialize(_)` — the argument is ignored (subclasses parse the host); seeds
  `id = 0` and the gas defaults `Tx::DEFAULT_PRIORITY_FEE` /
  `Tx::DEFAULT_GAS_PRICE` (R12).

### Public methods

| Method | Notes |
|---|---|
| `default_account` | memoized from `eth_accounts`; `ArgumentError` on a remote node unless set manually |
| `chain_id` | memoized from `eth_chain_id` |
| `get_balance(address)` / `get_nonce(address)` | nonce uses the `"pending"` tag |
| `resolve_ens(ens_name, registry = Ens::DEFAULT_ADDRESS, coin_type = Ens::CoinType::ETHEREUM)` | |
| `transfer(destination, amount, **kwargs)` / `transfer_and_wait(...)` | kwargs `sender_key:, legacy:, nonce:`; default gas `Tx::DEFAULT_GAS_LIMIT` |
| `transfer_erc20(erc20_contract, destination, amount, **kwargs)` / `_and_wait` | adds `gas_limit:, tx_value:` |
| `deploy(contract, *args, **kwargs)` / `deploy_and_wait(...)` | `ArgumentError` without `contract.bin` or on constructor arity mismatch; default gas `Tx.estimate_intrinsic_gas(data) + Tx::CREATE_GAS`; `_and_wait` sets `contract.address` |
| `call(contract, function, *args, **kwargs)` | kwargs `address, from, gas, gas_price, value, sender_key, legacy`; unwraps single-element results; `RpcError` → `ContractExecutionError` via `contract.decode_error` |
| `transact(contract, function, *args, **kwargs)` / `transact_and_wait(...)` | kwargs `sender_key, legacy, address, gas_limit, nonce, tx_value`; `_and_wait` → `[hash, success?]`. **R5:** the default gas estimate is computed from `contract.bin` (deployment bytecode), not the encoded calldata |
| `is_valid_signature(contract, hash, signature, magic = "1626ba7e")` | EIP-1271; `ArgumentError, "Contract not deployed yet."` if `contract.address` is nil |
| `reset_id`, `tx_mined?(hash)`, `tx_succeeded?(hash)` (status `"0x1"`), `wait_for_tx(hash)` (300 s timeout, 0.1 s poll, `Timeout::Error`) | |

### Metaprogrammed RPC methods

For every entry in `Api::COMMANDS` (≈286 names) a snake_case instance method is
defined (e.g. `eth_get_balance`, `eth_send_raw_transaction`) forwarding to
`send_command`. **R9:** `COMMANDS` is a Geth-1.10.26 snapshot plus later
additions; dead namespaces (`shh_*`, `db_*`, `les_*`, web3.js helper names)
become methods that can never succeed against a modern node.

### Private surface (notable)

`local?` (Ipc, or host `127.0.0.1`/`localhost`); `send_transaction(params,
legacy, key, nonce)` (with a key → signs `Eth::Tx.new(params).sign(key)` and
calls `eth_send_raw_transaction`; without a key → requires a local node and
`eth_send_transaction`); `send_command` (appends the `block_number` param only
for `eth_getBalance`/`eth_call`; raises `RpcError.new(message, data, code)` on an
`"error"` response); `marshal` (recursively hex-encodes numerics, `Address`
objects, hex strings, camelizes hashes).

## Eth::Client::Http

`class Client::Http < Client` — `attr_reader :host, :port, :uri, :ssl, :user`;
`initialize(host)` (`ArgumentError` unless http/https; rebuilds the `uri`
embedding `user:password` when present); `send_request(payload)` via
`HTTPX.plugin(:persistent)` with a JSON content type.

> **R2:** after the `Client::Http` class body, a stray `private` +
> `attr_reader :password` sit at `Eth` **module** scope — this defines
> `Eth.password`, not an `Http` accessor. The `@password` set in
> `Http#initialize` therefore has no public reader.

## Eth::Client::Ipc

`class Client::Ipc < Client` — `attr_accessor :path`; `initialize(path)`;
`send_request(payload)` over a `UNIXSocket`, reading until a trailing newline.

## Eth::Client::Ws

`class Client::Ws < Client` — `attr_reader :host, :port, :uri, :ssl`;
`initialize(host)` (`ArgumentError` unless ws/wss); `send_request(payload)`
(mutex-synchronized; retries once on `IOError`/`SystemCallError` after closing
the socket); `close`.

A full hand-rolled RFC-6455 client (no websocket gem): TLS with `VERIFY_PEER`,
default cert store, and hostname verification for `wss` (I12); `Sec-WebSocket-
Accept` validated against the SHA-1 magic GUID; client-masked frames; 7/16/64-bit
lengths; fragmentation, auto-pong on ping, close frame → `IOError`. It is
request/response — there is **no** `eth_subscribe` push support (SPEC §2
non-goal, R13).

## Eth::Api

`module Eth::Api` with `extend self` — `COMMANDS`, an array of ≈286 JSON-RPC
method-name strings across the `account_/admin_/clef_/clique_/db_/debug_/dev_/
eth_/les_/miner_/net_/personal_/rpc_/shh_/txpool_/web3_` namespaces. Consumed by
`Client`'s metaprogramming (R9).

---

## Cross-references

- `Client` builds and signs `Eth::Tx` (domain 04) and encodes/decodes calldata
  and errors via `Eth::Contract` (domain 06) and `Eth::Abi` (domain 03).
- `resolve_ens` delegates to `Ens::Resolver` (domain 06).
- Register items: **R2** (stray `password` reader), **R5** (`transact` gas from
  bytecode), **R9** (stale `COMMANDS`), **R12** (fee defaults), **R13** (no WS
  subscriptions). See [../../SPEC.md](../../SPEC.md) §9.
