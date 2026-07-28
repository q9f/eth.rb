<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# CLAUDE.md — working in eth.rb

Guide for any contributor (human or agent) working in this repository. It
summarizes the operating rules and points to the authoritative documents; where
this file and the specification disagree, the specification wins.

- **[SPEC.md](SPEC.md)** — identity, confirmed decisions (D1–D12), invariants
  (I1–I12), verification tiers, and the gap/quirk register (R1–R17).
- **[ACCEPTANCE.md](ACCEPTANCE.md)** — the executable pass/fail criteria your
  work is judged against.
- **[docs/spec/](docs/spec/)** — per-domain public-API contracts (six files).
- **[CONTRIBUTING.md](CONTRIBUTING.md)** / **[SECURITY.md](SECURITY.md)** — the
  project's existing contribution and disclosure policy.

## What this project is

`eth` is a library to build, sign, and broadcast Ethereum transactions anywhere
you can run Ruby, with strict separation of key management and node management.
Baseline v0.5.17. It is a stable 0.5.x line: prefer surgical, well-tested
changes over broad rewrites.

## Architecture map

Full map in [SPEC.md §3](SPEC.md). In short, `lib/eth/` groups into six domains,
each with a contract under `docs/spec/`:

1. **Foundations** — Constant, Unit, Util, Address, Chain, Rlp.
2. **Keys & Signatures** — Key (+ Encrypter/Decrypter), Signature, Eip712, Bls.
3. **ABI** — Abi (+ Type, Encoder, Decoder, Event, Function, Packed).
4. **Transactions** — Tx (+ Legacy, Eip2930, Eip1559, Eip4844, Eip7702).
5. **Client & RPC** — Client (+ Http, Ipc, Ws), Api.
6. **Contracts, ENS & Solidity** — Contract family, Ens (+ Resolver, CoinType),
   Solidity.

Read the relevant `docs/spec/` contract before changing a module — it lists the
public surface, error taxonomy, and the invariants you must preserve.

## How to make a change

1. **Register-first (SPEC D5).** Every defect, gap, or quirk belongs in the
   [SPEC.md §9](SPEC.md) register with an R-number and a disposition *before* a
   fix lands. Discovered something new? Add an entry (next free R-number; never
   reuse one). One register item = one unit of work — no drive-by fixes bundled
   into unrelated changes.
2. **Respect the compatibility surface (SPEC D4).** The public constants,
   classes, methods, attributes, error classes, and the exact error-message
   strings asserted by the suite are the contract. Changing any of them requires
   a register entry, an update to the matching `docs/spec/` file, and a
   CHANGELOG line — in the same change. Behavior marked `frozen-quirk` in the
   register is de-facto API; do not "fix" it casually.
3. **Document and cover as you go (SPEC D7).** New or changed code lands with
   100% line coverage and complete YARD docs. Overall coverage must never
   decrease.
4. **Format.** Run `rufo` before finishing.
5. **Keep SPEC and code in sync (SPEC §10).** After the change, SPEC's decisions
   and invariants must still hold; if they can't, change the decision first.

## Testing (verification tiers)

The suite is tiered (SPEC D6). Match the tier to your change; a green run is
required before calling work done.

**Tier 0 — offline, any machine** (no network, geth, solc, or submodule):

```shell
bundle exec rspec --exclude-pattern \
"spec/eth/client_spec.rb,spec/eth/ens/resolver_spec.rb,spec/eth/solidity_spec.rb,spec/eth/contract_spec.rb,spec/eth/contract/initializer_spec.rb,spec/eth/contract/event_spec.rb,spec/eth/rlp_spec.rb,spec/eth/abi_spec.rb,spec/eth/key/decrypter_spec.rb,spec/eth/key/encrypter_spec.rb"
```

**Tier 1 — full suite, CI parity** (required before "done"):

```shell
git submodule update --init --recursive
geth --dev --http --ws --ipcpath /tmp/geth.ipc >/tmp/geth.log 2>&1 & sleep 10
bundle install && bundle exec rspec
```

Needs `geth` and `solc` on `PATH`. If your machine can't host them, a green CI
"Spec" run (ubuntu + macos × Ruby 3.4/4.0) on the exact commit is acceptable
proof.

**Tier 2 — remote** (CI/scheduled only): a few examples in `client_spec` and
`ens/resolver_spec` reach the single remote host `https://eth.drpc.org`. They
are **embedded in the full Tier 1 suite** and cannot be isolated without RSpec
tags (SPEC R17) — so the full `bundle exec rspec` above also makes these remote
calls. **Run the full suite only in CI or with explicit human approval; agents
default to Tier 0 and never contact a remote host otherwise.**

Coverage report: `COVERAGE=1 bundle exec rspec` writes Cobertura XML to
`coverage/`. Docs check: `bundle exec yard doc` (stays `--fail-on-warning`
clean).

## Quality bars

- **Coverage:** 100% on new/changed lines; overall never decreases. The codecov
  gate (99% target, 1% threshold) is the enforced minimum; reaching true 100% is
  tracked as SPEC R15, not a precondition for unrelated work.
- **Docs:** 100% YARD on new/changed objects; `yard doc` warning-free.
- **Ruby (SPEC D8):** support is `>= 3.0, < 5.0`; do not use features beyond the
  3.0 floor. Raising it is a maintainer decision, not a side effect.
- **Dependencies (SPEC D9):** the runtime dependencies are load-bearing (native:
  keccak, rbsecp256k1, scrypt, bls12-381). No new dependency, vendoring, or
  removal without maintainer approval; version bumps go through dependabot + CI.

## Security (SPEC D11)

- The only private keys in the repo are published, well-known test vectors.
  Never add real key material; never fund the test keys.
- Changes to cryptographic paths (`key*`, `signature.rb`, `eip712.rb`, `rlp/`,
  `tx/`, `abi/`) must cite official vectors (ethereum/tests or EIP appendices),
  not only hand-rolled expectations.
- Do not add network egress. The test suite's only remote host is
  `eth.drpc.org`; production code contacts only caller-specified endpoints.
- Report vulnerabilities per [SECURITY.md](SECURITY.md) (private disclosure);
  land fixes with regression vectors.

## Releases (SPEC D10)

A release is: bump `lib/eth/version.rb`, add a `CHANGELOG.md` entry (one line per
merged PR, Added/Changed), open a release PR, then tag `vX.Y.Z` and `gem push`.
**Contributors and agents prepare every artifact; tagging and publishing are
human-maintainer actions only.** Do not push tags or publish gems.

## Current direction

The feature and fix lanes are driven by the SPEC register. High-signal items:

- **R8 (high)** — `Tx::Eip7702::Authorization#sign` omits the EIP-7702 `0x05`
  MAGIC prefix, so authorizations recover to the wrong authority on-chain. Any
  fix must validate against an external cross-client vector.
- **R7** — the `HOLESKY`/`HOLESOVICE` chain ID (11166111) never matched the live
  network; `HOODI` is the current test chain.
- **R13** — feature gaps: WS `eth_subscribe` push, EIP-4844 blob sidecars/KZG,
  BIP-32/39 HD wallets.

See [SPEC.md §9](SPEC.md) for the full register.
