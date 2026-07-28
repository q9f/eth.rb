<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# Domain 02 — Keys & Signatures

As-built API contract for the cryptographic layer: secp256k1 key pairs, Web3
Secret Storage keystores, message/typed-data signing and recovery, and BLS12-381
helpers. This is the security-critical core (SPEC D11): changes here require
official vectors, not just hand-rolled ones.

**Scope:** `Eth::Key` (+ `Encrypter`, `Decrypter`), `Eth::Signature`,
`Eth::Eip712`, `Eth::Bls`.
**Source:** `lib/eth/key.rb`, `lib/eth/key/`, `lib/eth/{signature,eip712,bls}.rb`.
**Parent spec:** [../../SPEC.md](../../SPEC.md) — invariants I1, I4, I5, I11.

---

## Eth::Key

`class Eth::Key` — secp256k1 key pair with signing. Autoloads `Decrypter`,
`Encrypter`. Depends on rbsecp256k1, plus `Eth::{Util,Chain,Signature,Eip712}`.

- **Readers:** `attr_reader :private_key`, `:public_key` (both `Secp256k1::*`
  objects).
- `initialize(priv: nil)` — generates a random pair (context with
  `context_randomization_bytes`) or restores from a hex/binary private key.
- `sign(blob, chain_id = nil)` → hex signature `r‖s‖v`, where
  `v = Chain.to_v(recovery_id, chain_id)` (supports chain IDs above 2³²). The
  doc marks raw `sign` "Should not be used unless really desired" — prefer
  `personal_sign`/`sign_typed_data`.
- `personal_sign(message, chain_id = nil)` → EIP-191 personal signature.
- `sign_typed_data(typed_data, chain_id = nil)` → EIP-712 signature via
  `Eip712.hash`.
- `private_hex`, `private_bytes`, `public_hex` (uncompressed),
  `public_hex_compressed`, `public_bytes`, `public_bytes_compressed`.
- `address` → `Eth::Address` (via `Util.public_key_to_address`).

**Invariant (I5):** signing is total over large chain IDs; the `v` byte is
serialized big-endian with leading zeros stripped.

## Eth::Key::Encrypter

`class Eth::Key::Encrypter` — Web3 Secret Storage Definition v3 writer
(aes-128-ctr). Depends on openssl, scrypt, securerandom.

- **Error:** `EncrypterError < StandardError`.
- `self.perform(key, password, options = {})` → JSON keystore string.
- `initialize(key, options = {})` — accepts a `Key` or a hex `String`; raises
  `EncrypterError` unless `kdf ∈ {"pbkdf2", "scrypt"}`.
- `perform(password)` → JSON string; `data` → the keystore `Hash`.

**Options / defaults:** `:kdf` (`"pbkdf2"`), `:id` (`SecureRandom.uuid`),
`:iterations` (`262_144`, also scrypt `N`), `:salt`, `:iv`, `:parallelization`
(`8`), `:block_size` (`1`). MAC = `keccak256(derived_key[16,32] ‖ ciphertext)`.
kdfparams: scrypt `{dklen: 32, n, p, r, salt}`; pbkdf2
`{c, dklen: 32, prf: "hmac-sha256", salt}`.

## Eth::Key::Decrypter

`class Eth::Key::Decrypter` — keystore reader.

- **Error:** `DecrypterError < StandardError`.
- `self.perform(data, password)` → `Eth::Key`.
- `initialize(data, password)` — accepts a JSON string or a `Hash`; tolerates
  `"crypto"` or `"Crypto"`.
- `perform` → `Eth::Key`.

**Invariant (I11):** supports `"pbkdf2"` (OpenSSL PKCS5, sha256) and `"scrypt"`;
any other kdf raises `DecrypterError, "Unsupported key derivation function: #{kdf}!"`;
the keccak MAC is verified **before** returning key material —
`"Message Authentications Codes do not match!"` on mismatch (note the upstream
spelling, which is asserted by the suite).

## Eth::Signature

`module Eth::Signature` with `extend self`. Depends on rbsecp256k1 and
`Eth::{Util,Chain,Eip712,Address}`.

- **Error:** `SignatureError < StandardError`.
- **Constants:** `EIP191_PREFIX_BYTE = "\x19"`, `EIP712_VERSION_BYTE = "\x01"`.
- `prefix_message(message)` → `"\x19Ethereum Signed Message:\n#{message.bytesize}#{message}"`
  (byte length, so multibyte messages are handled).
- `dissect(signature)` → `[r, s, v]` (r/s 64 hex chars each, v the remainder);
  raises `SignatureError, "Unknown signature length #{size}!"` below 130 hex chars.
- `recover(blob, signature, chain_id = Chain::ETHEREUM)` → uncompressed public
  key hex; enforces `v` unless ledger/legacy, else
  `SignatureError, "Invalid signature v byte #{v} for chain ID #{chain_id}!"`.
- `personal_recover(message, signature, chain_id = Chain::ETHEREUM)`.
- `recover_typed_data(typed_data, signature, chain_id = Chain::ETHEREUM)`.
- `verify(blob, signature, public_key, chain_id = Chain::ETHEREUM)` → Boolean.

**`verify` dispatch:** `blob` — Array/Hash → typed data; non-binary String →
personal message; hex/binary String → raw digest; otherwise
`"Unknown data format to verify: #{blob}"`. `public_key` — `Eth::Address`,
`Secp256k1::PublicKey`, 42-char address string, or 130-char uncompressed key;
otherwise `"Invalid public key or address supplied #{public_key}!"`. Passing a
private key is rejected.

## Eth::Eip712

`module Eth::Eip712` with `extend self` — EIP-712 typed structured data. Uses
`Eth::{Abi,Util,Signature}`. **Data is symbol-keyed** (`data[:types]`,
`field[:name]`).

- **Error:** `TypedDataError < StandardError`.
- `type_dependencies(primary_type, types, result = [])` — unwraps `T[...]` arrays.
- `encode_type(primary_type, types)` — primary first, deps alphabetical; raises
  `TypedDataError` on a non-primary type reference.
- `hash_type(primary_type, types)`.
- `encode_data(primary_type, data, types)` — typeHash + fields; strings/bytes/
  structs hashed to `bytes32`; arrays via `encode_array`.
- `encode_value(type, value, types)`, `encode_array(type, value, types)`.
- `hash_data(primary_type, data, types)`.
- `enforce_typed_data(data)` — JSON-parses hex input; requires non-empty
  `:types`, `:primaryType`, `:domain`, `:message`, and `types[:EIP712Domain]`.
- `hash(data)` → `keccak256(0x19 ‖ 0x01 ‖ domainSeparator ‖ messageHash)`.

## Eth::Bls

`module Eth::Bls` with `module_function` — BLS12-381 (compressed G1 pubkeys, G2
signatures). Requires the `bls` gem (dependency `bls12-381`) and `Eth::Util`.

- `decode_public_key(hex)` → `BLS::PointG1`; `encode_public_key(point)` → `0x` hex.
- `decode_signature(hex)` → `BLS::PointG2`; `encode_signature(point)` → `0x` hex.
- `get_public_key(priv_hex)` → compressed pubkey hex.
- `sign(message, priv_hex)` → signature hex (message is a raw digest, no
  hash-to-curve wrapper).
- `verify(message, signature_hex, pubkey_hex)` → Boolean.

**R16:** `bls.rb` is the only `lib/` file without the Apache license header —
a REUSE-compliance gap (fix-candidate).

---

## Cross-references

- `Eth::Key#sign`/`personal_sign`/`sign_typed_data` are consumed by every `Tx`
  type (domain 04) and by `Client` transfers (domain 05).
- `Signature.recover*` underpins address recovery in `Tx#sign_with`, EIP-1271
  checks (`Client#is_valid_signature`), and ENS ownership.
- `Eip712.hash` is shared by `Key#sign_typed_data` and
  `Signature.recover_typed_data`.
- Register items: **R16** (bls.rb header). See [../../SPEC.md](../../SPEC.md) §9.
