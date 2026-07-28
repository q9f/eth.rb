<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Domain 03 — ABI

As-built API contract for the Solidity Contract ABI: the type parser, head/tail
encoder and decoder, non-standard packed encoder, and event-log / function-call
decoders. Reference: <https://docs.soliditylang.org/en/develop/abi-spec.html>.

**Scope:** `Eth::Abi` (+ `Type`, `Encoder`, `Decoder`, `Event`, `Function`,
`Packed::Encoder`).
**Source:** `lib/eth/abi.rb`, `lib/eth/abi/`.
**Parent spec:** [../../SPEC.md](../../SPEC.md) — invariant I10 (decoder
bounds-safety), register R6.

---

## Eth::Abi

`module Eth::Abi` with `extend self`. Uses `Eth::{Util,Constant,Address}` and
konstructor/bigdecimal via its submodules.

- **Errors:** `EncodingError`, `DecodingError`, `ValueOutOfBounds`
  (all `< StandardError`).
- `encode(types, args, packed = false)` → binary blob; wraps non-array args;
  delegates to `solidity_packed` when `packed` is true.
- `solidity_packed(types, args)` → binary blob; `ArgumentError` on
  types/args length mismatch.
- `decode(types, data)` → `Array`; accepts hex or binary; raises
  `DecodingError, "Not enough data for head"` on truncation.

## Eth::Abi::Type

`class Eth::Abi::Type` — parsed representation of an ABI type. Uses konstructor.

- **Error:** `ParseError < StandardError`.
- **Readers:** `base_type`, `sub_type`, `dimensions`, `components`, `name`.
- `initialize(base_type, sub_type, dimensions, components = nil, component_name = nil)`
  — prefer `Type.parse`.
- `parse(type, components = nil, component_name = nil)` — the constructor
  (`konstructor :parse`); accepts a `Type`, a `tuple(...)`/`(...)` string, or a
  scalar/array type matching `\A([a-z]+)([0-9]*x?[0-9]*)((?:\[\d+\]|\[\])*)\z`.
  `uint`/`int` default their sub-type to `256`; a dynamic array dimension is
  stored as `0`.
- `self.size_type` → memoized `uint256` `Type`.
- `==(another_type)`, `size` (`nil` ⇒ dynamic; static tuple = Σ component sizes),
  `dynamic?` (= `size.nil?`), `nested_sub`, `to_s`.

**Validation rules (`validate_base_type`):** `string`/`tuple`/`address`/`bool`
forbid a suffix; `bytesN` requires `1 ≤ N ≤ 32`; `uint`/`int` size `8..256` and
a multiple of 8; `fixed`/`ufixed`/`real`/`ureal` require `<size>x<decimals>` where
`size + decimals` is in `8..256` and `size` is a multiple of 8; `hash`
requires a numeric suffix; anything
else raises `ParseError, "Unknown base type"`. The `hash`, `real`, and `ureal`
base types are non-standard aliases kept for compatibility.

## Eth::Abi::Encoder

`module Eth::Abi::Encoder` with `extend self`.

- `type(type, arg)` — encode a value of a parsed `Type` (dispatches arrays,
  tuples, dynamic vs static).
- `primitive_type(type, arg)` — encode a single primitive.

**Bounds and coercions:** `uint` within `[UINT_MIN, UINT_MAX]` and `< 2**N`;
`int` within `[-2**(N-1), 2**(N-1))`, encoded mod 2²⁵⁶; `bytesN` arg ≤ N bytes;
addresses accepted as `Eth::Address`, `Integer`, 20-byte binary, 40-hex, or
42-char `0x` hex; numeric strings coerced (hex via `to_i(0)`, decimals via
`BigDecimal`). **Fixed-point (R6):** scales by `2**low` — differs from the
packed encoder's `10**decimals`. Out-of-range values raise `ValueOutOfBounds`;
malformed types raise `EncodingError`.

## Eth::Abi::Decoder

`module Eth::Abi::Decoder` with `extend self`.

- `type(type, arg)` — decode a value of a parsed `Type`.
- `primitive_type(type, data)` — decode a single primitive.

**Invariant (I10):** offsets and sizes are validated — `DecodingError` with
`"Offset out of bounds"` / `"Wrong data size …"`, including rejection of
self-referential zero-size-type array offsets. `address` decodes to a
lowercased `0x` string; dynamic `string`/`bytes` are force-encoded UTF-8; `int`
uses two's-complement; `fixed`/`ufixed` return `Float` (`* 1.0 / 2**low`);
`bool` compares the final byte to `Constant::BYTE_ONE`.

## Eth::Abi::Event

`module Eth::Abi::Event` with `extend self` — event-log decoding.

- `compute_topic(interface)` → `0x…` keccak of the event signature.
- `signature(interface)` → canonical signature string.
- `type(input)` — resolves an input to a type string (tuples → `(...)`,
  `enum` → `uint8`).
- `decode_logs(interfaces, logs)` → **Enumerator** yielding
  `[log, LogDescription | nil]` (unknown topic → `nil`). *(R10: the YARD
  `@return` documents `[Hash]` — the real return is this Enumerator.)*
- `decode_log(inputs, data, topics, anonymous = false)` → `[args, kwargs]`;
  partitions inputs on `"indexed"`; skips `topics[0]` unless `anonymous`.
- **`class LogDescription`** — `attr_accessor :event_interface, :args, :kwargs,
  :topic`; `initialize(event_interface, log)`; `name`; `signature`.

## Eth::Abi::Function

`module Eth::Abi::Function` with `extend self` — function-call decoding.

- `signature(interface)`; `selector(interface)` (first 4 keccak bytes, `0x`
  prefixed); `type(input)`.
- `decode(interfaces, data)` → `CallDescription`, or `nil` for an unknown
  selector.
- **`class CallDescription`** — `attr_accessor :function_interface, :args,
  :kwargs, :selector`; `initialize(function_interface, selector, args, kwargs)`;
  `name`; `signature`.

## Eth::Abi::Packed::Encoder

`module Eth::Abi::Packed::Encoder` with `extend self` — Solidity
`abi.encodePacked` (no padding). `type(type, arg)` dispatches on type **strings**
(regex-matched: `uint\d+`, `int\d+`, `bool`, `ufixed/fixed \d+x\d+`, `string`,
`bytes\d+`, `bytes`, `tuple(...)`, `hash\d+`, `address`, `T[]`, `T[n]`).

`bool` → 1 byte; addresses → 20 bytes; fixed-size arrays raise `ArgumentError`
on a length mismatch; unknown types raise `Type::ParseError`. **Fixed-point
(R6):** scales by `10**decimals` while bounds-checking against `2**decimals` —
an inconsistency with both the standard encoder and itself.

---

## Cross-references

- `Eth::Abi` is consumed by `Eth::Contract` (domain 06) for calldata and by
  `Eth::Eip712` (domain 02) for struct-field encoding.
- `Eth::Abi::Event`/`Function` back `Contract::Event#decode_params` and
  `Contract::Function#decode_call_result`.
- Register items: **R6** (fixed-point scaling split), **R10** (decode_logs
  documented return type). See [../../SPEC.md](../../SPEC.md) §9.
