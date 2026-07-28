<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Domain 01 — Foundations

As-built API contract for the primitive layer: byte/number constants,
denominations, byte/hex/hash utilities, checksummed addresses, chain-ID math,
and the RLP codec with its serialization type system (sedes). Everything else
in the gem builds on these.

**Scope:** `Eth::Constant`, `Eth::Unit`, `Eth::Util`, `Eth::Address`,
`Eth::Chain`, `Eth::Rlp` (+ `Encoder`, `Decoder`, `Sedes`, `Sedes::BigEndianInt`,
`Sedes::Binary`, `Sedes::List`), plus the top-level `Eth` loader and
`Eth::VERSION`.
**Source:** `lib/eth/{constant,unit,util,address,chain}.rb`, `lib/eth/rlp.rb`,
`lib/eth/rlp/`, `lib/eth.rb`, `lib/eth/version.rb`.
**Parent spec:** [../../SPEC.md](../../SPEC.md) — invariants I1–I12, register
R1–R17 are cited inline as `(I2)`, `(R3)`.

---

## Eth::Constant

Shared byte and numeric constants; `extend self` is not used — these are plain
frozen constants under `module Eth::Constant`.

| Constant | Value |
|---|---|
| `BYTE_EMPTY` | `""` |
| `BYTE_ZERO` | `"\x00"` |
| `BYTE_ONE` | `"\x01"` |
| `UINT_MAX` | `2**256 - 1` |
| `UINT_MIN` | `0` |
| `INT_MAX` | `2**255 - 1` |
| `INT_MIN` | `-2**255` |
| `HASH_ZERO` | `"\x00" * 32` |
| `SHORT_LENGTH_LIMIT` | `56` |
| `LONG_LENGTH_LIMIT` | `256**8` |
| `PRIMITIVE_PREFIX_OFFSET` | `0x80` |
| `LIST_PREFIX_OFFSET` | `0xc0` |
| `BINARY_ENCODING` | `"ASCII-8BIT"` |
| `INFINITY` | `1.0 / 0.0` |

The RLP length limits and prefix offsets are consumed by the RLP encoder/decoder;
`INFINITY` is the default `max_length` of `Sedes::Binary`.

## Eth::Unit

Denomination constants as frozen `BigDecimal` (wei-valued). Depends on
`bigdecimal`.

| Constant | Wei | | Constant | Wei |
|---|---|---|---|---|
| `WEI` | `1e0` | | `SZABO` | `1e12` |
| `BABBAGE` | `1e3` | | `FINNEY` | `1e15` |
| `LOVELACE` | `1e6` | | `ETHER` | `1e18` |
| `SHANNON` | `1e9` | | `GWEI` | `= SHANNON` (`1e9`) |

## Eth::Util

`module Eth::Util` with `extend self` — every method is a module function.
Uses the `keccak` gem (`Digest::Keccak`), references `Secp256k1::PublicKey`
(rbsecp256k1), and delegates integer serialization to `Rlp::Sedes`.

**Public methods:**

| Method | Notes |
|---|---|
| `public_key_to_address(str)` | → `Eth::Address`; keccak of the uncompressed key minus its first byte, last 20 bytes |
| `keccak256(str)` | Keccak-256, original padding — **not** SHA3-FIPS (I1) |
| `bin_to_hex(bin)` | `TypeError` unless `str` is a `String` |
| `hex_to_bin(hex)` | `TypeError` unless hex; left-pads odd length |
| `prefix_hex(hex)` / `remove_hex_prefix(hex)` | add/strip `0x`; handle upper-case `0X` |
| `bin_to_prefixed_hex(bin)` | |
| `hex?(str)` / `prefixed?(hex)` | predicates (empty string counts as hex) |
| `serialize_int_to_big_endian(num)` | accepts hex strings; `ArgumentError` outside `0..UINT_MAX` |
| `int_to_big_endian(num)` | |
| `deserialize_big_endian_to_int(str)` | **lenient** — strips leading zero bytes first |
| `deserialize_rlp_int(str)` | **strict** minimal encoding — raises `Rlp::DeserializationError` on non-minimal input |
| `big_endian_to_int(str)` | |
| `str_to_bytes` / `bytes_to_str` / `bytes?` / `primitive?` / `list?` | type/encoding helpers |
| `ceil32(num)` | round up to multiple of 32 |
| `lpad(str, sym, len)` / `zpad(str, len)` / `zpad_hex(hex, len = 32)` / `zpad_int(num, len = 32)` | padding |

**Invariant:** the two integer-deserialize variants differ deliberately —
ABI decoding uses the lenient `deserialize_big_endian_to_int`; RLP and
transaction decoding use the strict `deserialize_rlp_int` (I2). Do not collapse
them.

## Eth::Address

`class Eth::Address` — EIP-55 checksummed address handling.

- **Constant:** `ZERO = "0x0000000000000000000000000000000000000000"`.
- **Error:** `CheckSumError < StandardError`.
- **Reader:** `attr_reader :address`.
- `initialize(address)` — raises `CheckSumError, "Unknown address type #{address}!"`
  when the input is not a hex address, or `CheckSumError, "Invalid address
  provided #{address}"` when a hex input fails the EIP-55 checksum.
- `valid?` → Boolean.
- `zero?` → Boolean (matches `ZERO`).
- `checksummed` → EIP-55 mixed-case form; `alias to_s checksummed`.

**Invariants (I3):** input must match `\A0[xX][a-fA-F0-9]{40}\z`; all-lower and
all-upper inputs are accepted as *unchecksummed*; a mixed-case input must match
the keccak-derived EIP-55 checksum or construction raises. `to_s` always returns
the checksummed form.

## Eth::Chain

`module Eth::Chain` with `extend self` — EIP-155 chain IDs and replay-protection
`v` math.

- **Error:** `ReplayProtectionError < StandardError`.
- **Chain-ID constants (selected):** `ETHEREUM 1`, `OPTIMISM 10`, `BNB 56`,
  `CLASSIC 61`, `XDAI 100` (`GNOSIS = XDAI`), `MATIC 137` (`POLYGON = MATIC`),
  `BASE 8453`, `ARBITRUM 42161`, `AVALANCHE 43114`, `SEPOLIA 11155111`,
  `HOODI 560048`, `BASECAMP 123420001114`, `PRIVATE_GETH 1337`, plus ~40 more
  mainnets/testnets. **`HOLESOVICE = 11166111`, aliased `HOLESKY` (R7 — never
  matched the live Holešky chain ID 17000; Hoodi is the current test chain).**
  Note `MORDEN = 2` collides with `EXPANSE = 2`.
- `ledger?(v)` → `v ∈ {0, 1}`.
- `legacy?(v)` → `v ∈ {27, 28}`.
- `to_recovery_id(v, chain_id = ETHEREUM)` → `0`/`1`; accepts ledger `v` as-is,
  legacy `v − 27`, EIP-155 `v − (2·chain_id + 35)` for exactly
  `{2c+35, 2c+36}`; otherwise raises `ReplayProtectionError`.
- `to_v(recovery_id, chain_id = nil)` → `27 + recovery_id` when chain nil/`<1`,
  else `2·chain_id + 35 + recovery_id`.
- `to_chain_id(v)` → chain ID, or `nil` when `v < 36` or the computed id `< 1`.

**Invariant (I5):** the `v` math is total over chain IDs above 2³²; only genuinely
invalid `v` raises.

## Eth::Rlp

`module Eth::Rlp` with `extend self` — recursive-length-prefix codec used by
every `Tx` class. Depends only on `Eth::Util` and `Eth::Constant`.

- **Errors:** `RlpException < StandardError`; `EncodingError`, `DecodingError`,
  `SerializationError`, `DeserializationError` all `< RlpException`.
- **`class Data < String`** — marker for already-encoded data (passed through).
- `encode(obj)` → binary RLP.
- `decode(rlp)` → object; accepts hex or binary.

### Rlp::Encoder (`extend self`)

`perform(obj)` infers a sedes, serializes, then raw-encodes. Private
`encode_raw`, `encode_primitive`, `encode_list`, `length_prefix` (raises
`EncodingError, "Length greater than 256**8: …"` above the limit).
**R3:** `encode_raw` contains `raise EncodingError "…"` (missing comma) — a
latent bug that would raise `NoMethodError` if that unreachable branch were hit.

### Rlp::Decoder (`extend self`)

`perform(rlp)` wraps any failure as `DecodingError, "Cannot decode rlp string: …"`
and rejects trailing bytes. Enforces canonicality (I2): rejects non-minimal
single-byte encodings, long-form prefixes used for short strings/lists, and
zero-prefixed lengths.

### Rlp::Sedes (singleton module)

`infer(obj)` (non-negative Integer → big-endian int; String → binary; list →
recursive `List`; else `TypeError`), `sedes?(obj)`, memoized `big_endian_int`,
memoized `binary`.

### Sedes classes

- **`BigEndianInt`** — `initialize(size = nil)`; `serialize(obj)` raises
  `SerializationError` with `"Cannot serialize negative integers"` or
  `"Integer too large (does not fit in N bytes)"`; `deserialize(serial)` raises
  `"Invalid serialization (wrong size)"` and rejects non-minimal leading zeros.
  `0` serializes to the empty string.
- **`Binary`** — `self.fixed_length(l, allow_empty: false)`, `self.valid_type?`,
  `initialize(min_length: 0, max_length: Constant::INFINITY, allow_empty: false)`,
  `serialize`/`deserialize` (`"Object has invalid length"` /
  `"#{class} has invalid length"`), `valid_length?`.
- **`List < Array`** — `initialize(elements: [], strict: true)` (`TypeError` for
  non-sedes members); `serialize`/`deserialize` raise `"List has wrong length"`
  on shape mismatch; deserialized result is frozen.

## Eth (module loader & version)

`lib/eth.rb` defines the top-level `module Eth` and `require`s every subsystem
in order (abi, api, address, chain, constant, contract, client, eip712, key,
rlp, signature, solidity, tx, unit, util, bls, ens, version). `lib/eth/version.rb`
holds the version constants: `MAJOR = 0`, `MINOR = 5`, `PATCH = 18`, and
`VERSION = [MAJOR, MINOR, PATCH].join(".")` (`"0.5.18"`) — the single source of
truth bumped at each release (SPEC D10).

---

## Cross-references

- Every `Tx` type (domain 04) encodes through `Rlp` and the sedes classes and
  inherits the strict decoding of I2.
- `Eth::Util.keccak256` is the single hashing entry point (I1); addresses,
  signatures, ABI, and EIP-712 all route through it.
- Register items touching this domain: **R3** (RLP encoder comma), **R7**
  (Holešky chain ID). See [../../SPEC.md](../../SPEC.md) §9.
