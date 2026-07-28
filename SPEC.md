<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# SPEC — eth.rb

Normative project specification for the `eth` gem: an as-built behavioral
contract for the 0.5.x line plus a register of known gaps, quirks, and
direction. It exists so that any contributor — human or agent — can change
this codebase without re-deriving its intent from ten years of history.

| | |
|---|---|
| **Baseline** | v0.5.17, commit `cedc60cc`, 2026-07-24 |
| **Status** | ACTIVE — all §4 decisions (D1–D12) explicitly confirmed 2026-07-24 |
| **Companions** | [ACCEPTANCE.md](ACCEPTANCE.md) (how work is judged) · [CLAUDE.md](CLAUDE.md) (contributor/agent guide) · [docs/spec/](docs/spec/) (per-domain API contracts) |

## 0. How to read this document

- **Descriptive facts** (what the code does): the code is authoritative. If
  this spec and the code disagree, the spec is wrong — file a register entry
  (§9), do not silently edit either side.
- **Intent and policy** (§2 scope, §4 decisions, §5 invariants, §6–§8): this
  spec is authoritative. Code changes that violate it require a decision
  change first.
- `docs/spec/*.md` are documentation contracts; the RSpec suite lives in
  `spec/` (do not confuse the two directories).

## 1. Identity

**Mission:** a straightforward library to build, sign, and broadcast Ethereum
transactions anywhere you can run Ruby — with strict separation of key
management and node management: sign and handle keys locally, broadcast
through any local or remote node.

| | |
|---|---|
| Gem | [`eth`](https://rubygems.org/gems/eth) |
| Repository | <https://github.com/q9f/eth.rb> |
| License | Apache-2.0 (see AUTHORS.txt for copyright holders) |
| Ruby | `>= 3.0, < 5.0` declared; CI-verified on 3.4 and 4.0 (ubuntu, macos) |
| Runtime deps | bigdecimal, forwardable, keccak, konstructor, rbsecp256k1, openssl, base64, scrypt, bls12-381, httpx |
| API docs | <https://q9f.github.io/eth.rb> (yard, `--fail-on-warning`) |

**Lineage** (the 10-year contract this spec inherits): started 2016-05-15 by
Steve Ellis as the `eth` gem (MIT, se3000/ruby-eth); adopted by Afri Schoedon
(q9f) in 2021; v0.5.0 (2022) was a complete rewrite that also merged
functionality from `ethereum.rb` (EthWorks), `ruby-ethereum-abi`, and
`ruby-rlp` (cryptape). 41 tags from v0.1.0 to v0.5.17; 399 commits;
CHANGELOG.md kept per release throughout.

## 2. Scope

**This library does (as built, v0.5.17):**

- secp256k1 key pairs; Web3 Secret Storage v3 keystores (pbkdf2, scrypt).
- Signing and recovery: raw digests, EIP-191 personal messages, EIP-712
  typed data; EIP-155 replay protection incl. chain IDs above 2³².
- All five transaction envelopes — legacy, EIP-2930 (0x01), EIP-1559 (0x02),
  EIP-4844 (0x03), EIP-7702 (0x04) — build, validate, sign, encode, decode.
- ABI encode/decode (head/tail, tuples, nested dynamic arrays), packed
  encoding, event-log and function-call decoding; strict-canonical RLP.
- JSON-RPC client over HTTP(S), IPC, and WS(S) with contract deploy / call /
  transact, ERC-20 helpers, EIP-1271 signature checks, ENS resolution.
- Solidity compilation via a system `solc` binary; BLS12-381 sign/verify.

**This library does not (as-built non-goals; changing any needs a §4-level
decision):**

- consensus-layer / beacon APIs, mempool management, chain indexing;
- HD wallets (no BIP-32/39 derivation, no mnemonics);
- WS push subscriptions (`eth_subscribe`) — the WS client is request/response;
- EIP-4844 blob **sidecar** construction (KZG commitments/proofs) — only
  `blob_versioned_hashes` handling;
- full UTS-46 ENS name normalization (see R11);
- key custody, HSM integration, or any telemetry/egress beyond
  caller-specified endpoints.

## 3. Architecture map

| Domain contract | Modules | Source |
|---|---|---|
| [docs/spec/01-foundations.md](docs/spec/01-foundations.md) | `Eth::Constant`, `Eth::Unit`, `Eth::Util`, `Eth::Address`, `Eth::Chain`, `Eth::Rlp` (+ Sedes), top-level `Eth` loader + `Eth::VERSION` | `lib/eth/{constant,unit,util,address,chain}.rb`, `lib/eth/rlp.rb`, `lib/eth/rlp/`, `lib/eth.rb`, `lib/eth/version.rb` |
| [docs/spec/02-keys-signatures.md](docs/spec/02-keys-signatures.md) | `Eth::Key` (+ Encrypter/Decrypter), `Eth::Signature`, `Eth::Eip712`, `Eth::Bls` | `lib/eth/key/`, `lib/eth/{key,signature,eip712,bls}.rb` |
| [docs/spec/03-abi.md](docs/spec/03-abi.md) | `Eth::Abi` (+ Type, Encoder, Decoder, Event, Function, Packed::Encoder) | `lib/eth/abi/`, `lib/eth/abi.rb` |
| [docs/spec/04-transactions.md](docs/spec/04-transactions.md) | `Eth::Tx` (+ Legacy, Eip2930, Eip1559, Eip4844, Eip7702) | `lib/eth/tx/`, `lib/eth/tx.rb` |
| [docs/spec/05-client-rpc.md](docs/spec/05-client-rpc.md) | `Eth::Client` (+ Http, Ipc, Ws), `Eth::Api` | `lib/eth/client/`, `lib/eth/{client,api}.rb` |
| [docs/spec/06-contracts-ens-solidity.md](docs/spec/06-contracts-ens-solidity.md) | `Eth::Contract` (+ Event, Function, FunctionInput, FunctionOutput, Initializer, Error), `Eth::Ens` (+ Resolver, CoinType), `Eth::Solidity` | `lib/eth/contract/`, `lib/eth/ens/`, `lib/eth/{contract,ens,solidity}.rb` |

## 4. Key decisions

Statuses: ⬜ proposed · ✅ confirmed. Each decision is numbered for citation;
numbers are never reused. D1–D12 were confirmed item-by-item on 2026-07-24.

**D1 — Mission lanes.** ✅
The framework serves three lanes of future work on the 0.5.x line:
(a) *maintenance & stewardship* — bug fixes, dependency and Ruby-version
upkeep, doc/test hygiene; (b) *feature work* — new EIPs, transaction types,
RPC surface; (c) *modernization & hardening* — internal improvement with no
public-API change. This spec is an as-built contract **plus** a direction
register (§9); it is never a speculative redesign document.

**D2 — Audience & placement.** ✅
`CLAUDE.md`, `SPEC.md`, `ACCEPTANCE.md` (repo root) and `docs/spec/*.md` are
upstream-ready: project-neutral in tone, free of any contributor's private
workflow rules, suitable in principle for submission to q9f/eth.rb.

**D3 — Spec structure.** ✅
Root `SPEC.md` holds identity, decisions, invariants, verification model, and
the register. Exactly six domain contracts under `docs/spec/` (table in §3)
hold the per-module public API surface. Domain files stay small and
independently reviewable; new domains require a decision here.

**D4 — Compatibility contract.** ✅
The public surface is: every public constant, class, method, and attribute
under `Eth::` as inventoried in the domain contracts; the error-class
taxonomy; and the exact error-message strings asserted by the RSpec suite.
Within 0.5.x, behavior changes to this surface require: a §9 register entry →
a dedicated change with tests → a CHANGELOG.md line. Quirks dispositioned
`frozen-quirk` in §9 are de-facto API until deliberately changed. Breaking
changes are reserved for a maintainer-decided version bump.

**D5 — Register discipline.** ✅
Every known defect, gap, or quirk lives in §9 with a disposition:
`fix-candidate`, `frozen-quirk`, `investigate`, `docs-gap`, or `feature-gap`.
One register item = one unit of work; no drive-by fixes bundled into
unrelated changes. Anyone discovering a new issue adds a register entry
(R-numbers are never reused) rather than silently fixing it.

**D6 — Verification tiers.** ✅
- **Tier 0 (offline)** — the pure subset of the RSpec suite passes on any
  machine: no network, no geth, no solc, no ethereum/tests submodule.
- **Tier 1 (CI parity)** — the full suite passes against a local
  `geth --dev --http --ws --ipcpath /tmp/geth.ipc`, with `solc` installed and
  the submodule initialized. Required before any work is called done. Because
  the suite is untagged (R17), the full run is monolithic: it also instantiates
  remote clients against `https://eth.drpc.org` (see Tier 2), so it is normally
  satisfied via CI rather than a local run.
- **Tier 2 (remote)** — the examples that reach the one remote host,
  `https://eth.drpc.org` (`client_spec`, `ens/resolver_spec`), are **embedded in
  the full suite** and cannot be isolated without RSpec tags (R17). They run
  only where egress exists — i.e. CI/scheduled. Agents run Tier 0 locally and
  never invoke the full suite (and thus never contact a remote host) without
  explicit human approval.
ACCEPTANCE.md defines the executable form of each tier.

**D7 — Quality bars.** ✅
New or changed code lands with 100% line coverage and complete YARD
documentation; `yard doc` stays `--fail-on-warning` clean; everything is
rufo-formatted. Overall repo coverage never decreases (the codecov gate —
99% target, 1% threshold — is the enforced floor). True 100% coverage and
100% doc coverage are tracked modernization goals (R15), not preconditions
for unrelated work.

**D8 — Ruby & platform support.** ✅
Declared support: `>= 3.0, < 5.0` (gemspec). Verified support: the CI matrix
(ubuntu + macos × Ruby 3.4, 4.0). Code must not require syntax or stdlib
behavior beyond the declared floor. Raising the floor is a deliberate
maintainer decision, never a side effect of a change.

**D9 — Dependency policy.** ✅
The ten runtime dependencies (§1) are load-bearing — especially the native
ones: keccak, rbsecp256k1, scrypt, bls12-381. No new runtime dependency, no
vendoring, no removal without explicit maintainer approval. Version bumps
follow the existing dependabot + CI flow.

**D10 — Release process.** ✅
A release is: `lib/eth/version.rb` bump + `CHANGELOG.md` entry (one line per
merged PR, Added/Changed sections) + a single release PR + git tag `vX.Y.Z` +
`gem push`. Contributors and agents may prepare every artifact; only human
maintainers tag, push, and publish.

**D11 — Security posture.** ✅
No private-key material beyond the published, well-known test keys already in
`spec/`/`spec/fixtures/keys/`. Changes to cryptographic paths (keys,
keystores, signatures, RLP/transaction encoding) require official vectors
(ethereum/tests, EIP reference vectors) in addition to any hand-rolled ones.
No new network egress paths: the test suite's only remote host stays
`eth.drpc.org` unless maintainers decide otherwise. Vulnerabilities follow
SECURITY.md — never public issues first.

**D12 — Direction register.** ✅
The feature lane is driven by §9 entries, currently headlined by:
R8 (EIP-7702 authorization signing lacks the `0x05` MAGIC prefix — signatures
produced are invalid on-chain), R7 (stale Holešky chain ID), and the R13
feature gaps (WS `eth_subscribe`, EIP-4844 blob sidecars, HD wallets).
New EIP support enters the codebase via a register entry first.

## 5. Cross-cutting invariants

These hold across the entire library; every change must preserve them. Domain
contracts list per-module invariants.

- **I1 — Keccak-256, not SHA3-FIPS.** All hashing uses original-padding
  Keccak-256 (`Eth::Util.keccak256`); the suite asserts the distinction.
- **I2 — Strict canonical RLP decoding.** Non-minimal integer encodings,
  wrong length prefixes, zero-prefixed lengths, and trailing bytes are all
  rejected with `Rlp` errors. Transaction decoding inherits this strictness.
- **I3 — Addresses are checksum-safe.** `Eth::Address.new` raises
  `CheckSumError` on EIP-55 violations; `to_s` always returns the
  checksummed form; all-lower/all-upper inputs are accepted as unchecksummed.
- **I4 — One-shot signing.** Re-signing a signed transaction or authorization
  raises; a signer/sender mismatch raises; `encoded`/`hex`/`hash` on an
  unsigned transaction raise (`Signature::SignatureError`).
- **I5 — EIP-155 v math is total.** Chain IDs above 2³² work; ledger v
  (0/1) and pre-155 legacy v (27/28) are accepted; anything else invalid
  raises `Chain::ReplayProtectionError`.
- **I6 — Gas floors at construction.** Every transaction validates
  `gas_limit >= estimated intrinsic gas` ("try N!" errors); the 30M block
  cap is enforced only for chain ID 1.
- **I7 — Key/node separation.** `Eth::Client` never requires key material
  unless the caller passes `sender_key`; nothing phones home; only
  caller-specified endpoints are contacted.
- **I8 — Stable error taxonomy.** The error classes inventoried in the domain
  contracts (e.g. `Tx::ParameterError`, `Abi::DecodingError`,
  `Client::RpcError` with `data`/`code`) are public API.
- **I9 — Envelope round-trips.** For all five types:
  `Tx.decode(tx.hex)` reproduces the transaction; unsigned payloads decode
  with blank sender and zero r/s; `unsigned_copy` preserves semantics.
- **I10 — ABI decoder bounds-safety.** Offsets and sizes are validated
  ("Offset out of bounds", "Wrong data size"), including rejection of
  self-referential zero-size-type offsets.
- **I11 — Keystore compliance.** Web3 Secret Storage v3; pbkdf2 and scrypt;
  MAC verification precedes any key material return.
- **I12 — TLS on wss.** The hand-rolled RFC-6455 client verifies peers
  (`VERIFY_PEER`, default cert store, hostname verification).

## 6. Verification model

| Tier | What runs | Needs | When |
|---|---|---|---|
| 0 | offline-pure subset (33 of 43 spec files fully; 4 more partially) | Ruby + bundle only | every change, any machine |
| 1 | full suite — also contacts `eth.drpc.org` (Tier 2 embedded, R17) | local `geth --dev --http --ws --ipcpath /tmp/geth.ipc`, `solc`, `git submodule update --init --recursive`, **egress** | required before "done" (via CI if no local egress/approval); CI on every PR/push (ubuntu+macos × 3.4/4.0) |
| 2 | remote examples embedded in the full suite (`eth.drpc.org` in `client_spec`, `ens/resolver_spec`); not isolable without tags (R17) | egress | CI / scheduled daily run only |

ACCEPTANCE.md is the executable definition (exact commands, exclusion lists,
and pass criteria). CI additionally gates codecov (99%/1%), yard
(`--fail-on-warning` via docs workflow), and CodeQL.

## 7. Release process

As observed across 41 releases and confirmed as policy (D10):

1. All changes merged via PR to `main`, each with a CHANGELOG-worthy title.
2. Release PR: bump `lib/eth/version.rb` (MAJOR/MINOR/PATCH + VERSION),
   update `CHANGELOG.md` with Added/Changed lists linking merged PRs.
3. Human maintainer tags `vX.Y.Z` on the merge commit and publishes with
   `gem push` (gem owners only).
4. Docs deploy to GitHub Pages via the docs workflow; the wiki carries usage
   examples.

## 8. Security posture

- Private keys appearing anywhere in the repo are *well-known test keys*
  (published fixtures/vectors) only; never fund them, never add real ones.
- Cryptographic behavior changes require official upstream vectors
  (ethereum/tests, EIP appendices) — hand-rolled expectations alone are
  insufficient (D11).
- Network surface is closed by default: production code contacts only
  caller-specified endpoints; the test suite's sole remote host is
  `eth.drpc.org` (Tier 2). Adding any other egress is a D-level decision.
- Vulnerability reports follow SECURITY.md (private disclosure), and fixes
  land with regression vectors.
- Keystore files decrypt only after MAC verification (I11); no plaintext key
  material in logs or error messages.

## 9. Gap & quirk register

Dispositions: `fix-candidate` (should be fixed; needs its own change),
`frozen-quirk` (de-facto API; do not change without D4 process),
`investigate` (impact unclear; analysis first), `docs-gap` (docs wrong or
missing), `feature-gap` (absent capability, feature lane). Evidence:
**verified** = confirmed in source during spec authoring; *reported* = from
exhaustive code digest, not yet independently re-checked.

| # | Finding | Evidence | Disposition |
|---|---|---|---|
| R1 | gemspec `require_paths = ["lib", "abis"]` references a directory that does not exist (the ABI JSONs live in `abi/`, loaded by relative path from `Ens::Resolver`) | **verified** `eth.gemspec:31`, `lib/eth/ens/resolver.rb:42,64` | fix-candidate |
| R2 | Stray `private` + `attr_reader :password` at `Eth` module scope after `Client::Http`'s class body — defines `Eth.password`, not an Http accessor | **verified** `lib/eth/client/http.rb:74-77` | fix-candidate |
| R3 | `raise EncodingError "…"` missing comma → would raise `NoMethodError` instead of `EncodingError` if that branch is ever reached | **verified** `lib/eth/rlp/encoder.rb:46` | fix-candidate |
| R4 | `Contract::Function#encode_call` appends `"0" * 64` when arg encoding is empty → zero-arg calls send selector + 32 zero bytes (nonstandard calldata) | **verified** `lib/eth/contract/function.rb:64` | investigate |
| R5 | `Client#transact` estimates intrinsic gas from `contract.bin` (deployment bytecode) instead of the encoded calldata; `deploy` (line 246) is correct | **verified** `lib/eth/client.rb:326` | investigate |
| R6 | Fixed-point semantics split: standard ABI encoder scales `fixed`/`ufixed` by `2**N`; packed encoder scales by `10**N` yet bounds-checks against `2**decimals` | **verified** `lib/eth/abi/encoder.rb:121,130-131`, `lib/eth/abi/packed/encoder.rb:99-108` | investigate |
| R7 | `HOLESOVICE = 11166111` (aliased `HOLESKY`) never matched the live Holešky testnet (17000, itself since sunset in favor of Hoodi — `HOODI = 560048` is present and correct) | **verified** `lib/eth/chain.rb:153-162` | fix-candidate |
| R8 | **EIP-7702 `Authorization#sign` omits the `0x05` MAGIC prefix**: it signs `keccak256(rlp([chain_id, address, nonce]))` where the EIP requires `keccak256(0x05 ‖ rlp([chain_id, address, nonce]))` — authorizations signed by this gem recover to the wrong authority on-chain. Decoding foreign transactions is unaffected. | **verified** `lib/eth/tx/eip7702.rb:97-110` | fix-candidate (high) |
| R9 | `Api::COMMANDS` is a Geth-1.10.26 snapshot plus later additions; dead namespaces (`shh_*`, `db_*`, `les_*`, web3.js helper names) become client methods that can never succeed | *reported* `lib/eth/api.rb` | frozen-quirk |
| R10 | Doc holes vs the 100% claim: all `attr_*` in the `Contract` family undocumented; wrong `@return` types (`Abi::Event.decode_logs` → Enumerator not `[Hash]`; `Contract::Event#decode_params` → plain Hash, not ActiveSupport); `Client.create` doc brace typo | *reported*; brace typo **verified** `lib/eth/client.rb:65` | docs-gap |
| R11 | `Ens::Resolver#normalize` documents UTS-46/tr46 normalization but implements only an ASCII blacklist + downcase | *reported* `lib/eth/ens/resolver.rb` | docs-gap / feature-gap |
| R12 | `Tx::DEFAULT_PRIORITY_FEE` (1.01 gwei) and `DEFAULT_GAS_PRICE` (42.69 gwei) are documented "Do not use." yet are `Client`'s fee defaults | **verified** `lib/eth/tx.rb:44-48`, `lib/eth/client.rb:84-85` | investigate |
| R13 | Feature gaps (§2 non-goals candidates for the feature lane): WS `eth_subscribe` push, EIP-4844 blob sidecars/KZG, BIP-32/39 HD derivation | **verified** (absent) | feature-gap |
| R14 | Test hygiene: empty `describe "Authorization"` block; `client_spec` header comment says `--wc` for `--ws` | *reported* `spec/eth/tx/eip7702_spec.rb:253`, `spec/eth/client_spec.rb` | fix-candidate (trivial) |
| R15 | Coverage and doc coverage below the stated 100% goal (codecov gate at 99%) | README, codecov.yml | modernization target |
| R16 | `lib/eth/bls.rb` carries no license header — the only `lib/` file missing one (all others have the 13-line Apache header), breaking REUSE/licensing uniformity | **verified** `lib/eth/bls.rb:1-3` (starts `# frozen_string_literal: true` then `require "bls"`, no header) | fix-candidate |
| R17 | The RSpec suite carries no tags/metadata to isolate remote/geth/solc/submodule examples; `client_spec.rb` mixes local-geth and remote-`eth.drpc.org` examples in one untagged file, so a full local `rspec` run cannot avoid contacting `eth.drpc.org` except by excluding whole files (which also drops their local coverage). Tiered runs beyond whole-file exclusion require adding RSpec tags first | **verified** `spec/eth/client_spec.rb:19-22` (drpc subjects beside geth examples); no `:tag`/`--tag` usage in `spec/` | fix-candidate (test-hygiene) |

## 10. Maintaining this spec

- **Drift check:** at every checkpoint (PR, release, agent hand-off), changes
  are re-read against §4 decisions and §5 invariants; a conflict blocks the
  change or triggers a decision update — never a silent divergence.
- **Register-first:** new findings get an R-number before any fix lands (D5).
- **Decision changes:** edit the decision in place, keep its number, note the
  date and reason; obsolete decisions are struck through, never deleted.
- **Baseline updates:** after each release, update the baseline line in the
  header table.
