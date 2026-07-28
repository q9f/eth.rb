<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Domain 04 — Transactions

As-built API contract for transaction construction, validation, EIP-2718
envelope encoding, decoding, and signing across all five transaction types.
This is the behavioral heart of the library and the strictest surface for the
compatibility contract (SPEC D4): the exact `ParameterError`/`DecoderError`
strings below are asserted by the suite and are therefore public API.

**Scope:** `Eth::Tx` (+ `Legacy`, `Eip2930`, `Eip1559`, `Eip4844`, `Eip7702`,
`Eip7702::Authorization`).
**Source:** `lib/eth/tx.rb`, `lib/eth/tx/`.
**Parent spec:** [../../SPEC.md](../../SPEC.md) — invariants I2, I4, I6, I9;
register R8 (high).
**EIPs:** 155, 1559, 2028, 2718, 2930, 3860, 4844, 7691, 7702.

---

## Eth::Tx (module)

`module Eth::Tx` with `extend self` — the factory, decoder, and shared
validators/sanitizers. Uses `Eth::{Chain,Unit,Util,Rlp,Signature,Address,Key}`.

- **Errors:** `TransactionTypeError < TypeError`, `DecoderError < StandardError`,
  `ParameterError < TypeError`.
- **Constants:** `DEFAULT_GAS_LIMIT 21_000`; `DEFAULT_PRIORITY_FEE`
  (`1.01 · GWEI`) and `DEFAULT_GAS_PRICE` (`42.69 · GWEI`) — both `BigDecimal`,
  both documented **"Do not use."** yet used as `Client`'s defaults (R12);
  `COST_NON_ZERO_BYTE 16`, `COST_ZERO_BYTE 4`, `COST_INITCODE_WORD 2`,
  `COST_STORAGE_KEY 1_900`, `COST_ADDRESS 2_400`, `BLOCK_GAS_LIMIT 30_000_000`,
  `TYPE_LEGACY 0x00`, `TYPE_2930 0x01`, `TYPE_1559 0x02`, `TYPE_4844 0x03`,
  `TYPE_7702 0x04`, `ZERO_BYTE "\x00"`, `CREATE_GAS 32_000`.

### Factory & codec

- `new(params, chain_id = Chain::ETHEREUM)` — dispatch by key presence, in order:
  `:max_fee_per_blob_gas` → `Eip4844`; `:authorization_list` → `Eip7702`;
  `:max_gas_fee` → `Eip1559`; `:access_list` → `Eip2930`; else `Legacy`.
  A `chain_id` inside `params` wins over the argument.
- `decode(hex)` — first byte `0x02/0x01/0x03/0x04` → typed decode; `≥ 0xc0` →
  `Legacy`; otherwise `TransactionTypeError, "Cannot decode unknown transaction
  type #{type}!"`.
- `unsigned_copy(tx)` — dispatch on `tx.type`; else
  `TransactionTypeError, "Cannot copy unknown transaction type #{tx.type}!"`.
- `estimate_intrinsic_gas(data = "", list = [])` = `21_000` + `4`/zero-byte +
  `16`/non-zero-byte + `2 · ceil(len/32)` (EIP-3860 word cost, applied to **all**
  calldata) + `2_400` per access-list entry + `1_900` per storage key.

### Validators (all raise `ParameterError`)

| Method | Rules and exact messages |
|---|---|
| `validate_params` | nonce ≥ 0 (`"Invalid signer nonce …!"`); gas_limit ≥ 21_000 and ≤ 30_000_000 **only when chain_id == 1** (`"Invalid gas limit …!"`); value ≥ 0 (`"Invalid transaction value …!"`); access_list nil-or-Array (`"Invalid access list …!"`) |
| `validate_eip1559_params` | `"Invalid gas priority fee …!"`, `"Invalid max gas fee …!"` |
| `validate_eip4844_params` | `"Invalid max blob fee …!"`, `"Invalid blob versioned hashes …!"`, `"Too many blob versioned hashes …!"` (> `MAX_BLOBS_PER_BLOCK`), `"Invalid destination address …!"` (`to` required) |
| `validate_eip7702_params` | `"Invalid authorization list …!"` |
| `validate_legacy_params` | `"Invalid gas price …!"` |

### Sanitizers

`sanitize_chain(id)` (nil → 1), `sanitize_address(addr)` (nil → `""`, else
checksummed and de-prefixed), `sanitize_amount(val)` (nil → 0),
`sanitize_data(data)` (nil → `""`, hex → binary), `sanitize_list(list)`,
`sanitize_hashes(list)`, `signed?(tx)` (`r` and `s` present and non-zero).

## Shared instance contract (all five classes)

Every type constructs via `konstructor :decode, :unsigned_copy` and implements:

- `sign(key)` — signs; raises `Signature::SignatureError, "Signer does not match
  sender"` on a sender/signer mismatch, and refuses to double-sign.
- `sign_with(signature)` — attaches an external signature (same guards).
- `encoded` — raises `Signature::SignatureError, "Transaction is not signed!"`
  when unsigned; otherwise the raw (EIP-2718-enveloped for typed) transaction.
- `hex` = `bin_to_hex(encoded)`; `hash` = keccak of `encoded`, hex.
- `unsigned_encoded`, `unsigned_hash`.
- Construction raises `ParameterError, "Transaction gas limit is too low, try
  #{minimum_cost}!"` when `gas_limit` < intrinsic estimate (I6).
- Typed decoders raise `ParameterError, "Transaction missing fields!"` on the
  wrong field count; a structurally malformed typed payload raises
  `DecoderError, "Cannot decode EIP-XXXX payload!"`.

**Invariants:** one-shot signing (I4); envelope round-trips — `decode(hex)`
reproduces the transaction, unsigned payloads decode with blank sender and zero
`r`/`s`, `unsigned_copy` preserves semantics (I9); non-minimal RLP integers are
rejected on decode (I2).

## Per-type specifics

### Tx::Legacy

Readers: `signer_nonce, gas_price, gas_limit, destination, amount, payload,
signature_v, signature_r, signature_s, chain_id, sender, type`.
`initialize(params, chain_id = Chain::ETHEREUM)` seeds `{v: chain_id, r: 0,
s: 0}` (EIP-155). RLP fields: nonce, gas_price, gas_limit, to, value, data, v,
r, s. `decode` requires ≥ 9 fields and recovers chain_id from `v` via
`Chain.to_chain_id` (`nil` for pre-155 → blank sender).

### Tx::Eip2930 (type 0x01)

Adds `access_list`; uses `signature_y_parity` in place of `v`.
`initialize(params)`. Fields: chain_id, nonce, gas_price, gas_limit, to, value,
data, access_list (+ y_parity, r, s). Decode accepts 8 (unsigned) or 11 fields.

### Tx::Eip1559 (type 0x02)

Readers include `max_priority_fee_per_gas`, `max_fee_per_gas`, `access_list`,
`signature_y_parity`. Params use `:priority_fee`, `:max_gas_fee`. Decode accepts
9 or 12 fields.

### Tx::Eip4844 (type 0x03)

Constants: `GAS_PER_BLOB = 2**17` (131_072), `TARGET_BLOB_GAS_PER_BLOCK
786_432`, `MAX_BLOB_GAS_PER_BLOCK 1_179_648`, `MAX_BLOBS_PER_BLOCK = MAX_BLOB_
GAS_PER_BLOCK / GAS_PER_BLOB = 9` (per EIP-7691). Adds `max_fee_per_blob_gas`,
`blob_versioned_hashes`; `to` is mandatory. Decode accepts 11 or 14 fields.
Handles only versioned hashes, **not** blob sidecars/KZG (SPEC §2 non-goal, R13).

### Tx::Eip7702 (type 0x04)

Adds `authorization_list`. Decode accepts 10 or 13 fields; a truncated payload
raises `DecoderError, "Cannot decode EIP-7702 payload!"`. `unsigned_copy`
preserves authorization signatures.

#### Tx::Eip7702::Authorization

Signed 3-tuple authorizing a code delegation. Readers: `chain_id, address,
nonce, signature_y_parity, signature_r, signature_s`.
`initialize(fields)` (keys `:chain_id, :address, :nonce, :recovery_id, :r, :s`).
`sign(key)`, `unsigned_encoded`, `unsigned_hash`, `raw` (6-tuple for embedding),
`==(other)`.

> **R8 (high) — signing is wrong.** `unsigned_encoded` returns
> `rlp([chain_id, address, nonce])` and `unsigned_hash` is its plain keccak.
> EIP-7702 mandates the `0x05` MAGIC domain-separator byte:
> `keccak256(0x05 ‖ rlp([chain_id, address, nonce]))`. Authorizations signed by
> this gem recover to the wrong authority on-chain. **Decoding** third-party
> type-4 transactions is unaffected (it never recomputes the authority). Any fix
> must validate against an external cross-client vector, not the gem's internal
> round-trip. See [../../SPEC.md](../../SPEC.md) §9 R8.

---

## Cross-references

- Every type encodes through `Rlp` + sedes (domain 01) and signs through
  `Eth::Key` / `Eth::Signature` (domain 02).
- `Eth::Client#send_transaction` (domain 05) builds and signs these when a
  `sender_key` is supplied.
- Register items: **R8** (EIP-7702 signing, high), **R12** (fee-constant
  "Do not use." vs Client defaults), **R13** (blob sidecars absent).
