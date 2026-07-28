<!--
SPDX-FileCopyrightText: 2016-2026 The Ruby-Eth Contributors
SPDX-License-Identifier: Apache-2.0
-->

# ACCEPTANCE — eth.rb

Executable acceptance criteria for work in this repository. A reviewer with
zero context beyond this file, the repository, and its toolchain must be able
to reach a PASS/FAIL verdict on every criterion.

No earlier acceptance document exists in this repository's history (checked
back to the 2016 initial commit); the format below follows the conventions of
its companion [SPEC.md](SPEC.md), which defines the decisions (D1–D12),
invariants (I1–I12), and register entries (R1–R17) cited here.

- **Part A** applies to every change to the library, forever.
- **Part B** applies to the specification framework itself (SPEC.md,
  ACCEPTANCE.md, CLAUDE.md, docs/spec/) — both its initial creation and any
  later edit to those files.

Verdict rule: a change is accepted only if every applicable criterion passes.
A criterion may be marked N/A only where its own text allows it.

## Part A — changes to the library

### A0. Preconditions (reviewer toolchain)

| Tier | Requirements |
|---|---|
| Tier 0 | Ruby ≥ 3.0 (3.4 recommended), `bundle install` |
| Tier 1 | Tier 0 + `geth` and `solc` on PATH + `git submodule update --init --recursive` + a running dev node: `geth --dev --http --ws --ipcpath /tmp/geth.ipc` |
| Tier 2 | Tier 1 + egress to `https://eth.drpc.org` — CI/scheduled runs only (SPEC D6) |

### A1. Scope discipline (SPEC D5)

**Check:** the change names exactly one SPEC §9 register item, one confirmed
decision, or one declared feature; `git diff` contains no hunks unrelated to
that scope (no drive-by fixes, no opportunistic reformatting of untouched
code).
**Pass:** single scope, all hunks attributable to it.

### A2. Tier 0 — offline suite passes

**Command** (any machine, no network, no geth/solc/submodule):

```shell
bundle exec rspec --exclude-pattern \
"spec/eth/client_spec.rb,spec/eth/ens/resolver_spec.rb,spec/eth/solidity_spec.rb,spec/eth/contract_spec.rb,spec/eth/contract/initializer_spec.rb,spec/eth/contract/event_spec.rb,spec/eth/rlp_spec.rb,spec/eth/abi_spec.rb,spec/eth/key/decrypter_spec.rb,spec/eth/key/encrypter_spec.rb"
```

The ten excluded files need geth, solc, `eth.drpc.org`, or the
`ethereum/tests` submodule (fully or partially); the remaining 33 files are
offline-pure. The globs are written relative to the default `spec` load path
(RSpec joins it, so `spec/eth/client_spec.rb` is matched); run from the
repository root. *(The bare `eth/…` form also matches, but the `spec/…` form is
used for clarity and to mirror the RSpec documentation.)*
**Pass:** 0 failures, 0 errors.

### A3. Tier 1 — full suite passes (CI parity)

**Setup + command:**

```shell
git submodule update --init --recursive
geth --dev --http --ws --ipcpath /tmp/geth.ipc &  # wait ~10s
bundle exec rspec
```

**Pass:** 0 failures. The suite currently contains **zero**
pending/skipped examples; any newly introduced `pending`/`skip` fails this
criterion unless the change's description justifies it and SPEC §9 records
it. If the reviewer's machine cannot host geth/solc, a green CI "Spec" run
(ubuntu + macos × Ruby 3.4/4.0) on the exact commit satisfies A3; Tier 2
examples are judged by CI only. Note the full `bundle exec rspec` also
instantiates remote clients against `https://eth.drpc.org` (`client_spec`,
`ens/resolver_spec`), and the suite has no tag to isolate them (SPEC R17) — so
a local full run makes remote calls. Run it only in CI or with explicit human
approval; otherwise stay at Tier 0 (A2).

### A4. Coverage (SPEC D7)

**Command:** `COVERAGE=1 bundle exec rspec` (Tier 1 environment), then read
`coverage/coverage.xml` (Cobertura).
**Pass:** every line of every added/changed `lib/` file is covered (100% on
changed code); overall line rate ≥ 0.99 and not lower than the value on
`main` before the change.

### A5. Documentation (SPEC D7)

**Commands:** `bundle exec yard doc` (honors `.yardopts`, including
`--fail-on-warning`) and `bundle exec yard stats --list-undoc`.
**Pass:** `yard doc` exits 0; no object in an added/changed file appears in
the `--list-undoc` output; pre-existing undocumented objects (SPEC R10) do
not increase in count.

### A6. Formatting

**Command:** `bundle exec rufo --check .`
**Pass:** exit 0 (no file would be reformatted).

### A7. Compatibility surface (SPEC D4)

**Check:** for every changed file under `lib/`, compare its public surface
(public constants, classes, methods, attributes, and raised error classes /
message strings) against the matching contract in `docs/spec/`:

1. Removed/renamed public symbols, changed signatures or defaults, or changed
   error strings asserted by the suite ⇒ FAIL, unless the change carries the
   D4 process evidence: a SPEC §9 register entry, the domain contract updated
   in the same change, and a CHANGELOG-worthy description.
2. Edits to existing spec expectations (`git diff -- spec/` touching
   `raise_error` strings or `eq` vectors) are treated as behavior changes and
   require the same evidence.
3. Behavior dispositioned `frozen-quirk` in SPEC §9 is unchanged.

**Pass:** no undocumented surface change.

### A8. Security (SPEC D11)

**Checks:**

1. `git diff main -- lib spec | grep -Ei "(https?|wss?)://"` introduces no
   host other than `127.0.0.1`, `localhost`, or `eth.drpc.org` (documentation
   links exempt).
2. No new private-key material except published, well-known test vectors with
   provenance stated in the change description.
3. Changes touching cryptographic paths (`lib/eth/key*`, `signature.rb`,
   `eip712.rb`, `rlp/`, `tx/`, `abi/`) cite official vectors (ethereum/tests
   or EIP appendices) among their added tests.

**Pass:** all three hold.

### A9. Dependencies and Ruby floor (SPEC D8, D9)

**Check:** `git diff main -- eth.gemspec Gemfile` is empty unless the change
description records explicit maintainer approval; no added code requires
Ruby features beyond the declared `>= 3.0` floor.
**Pass:** both hold.

### A10. Changelog and release hygiene (SPEC D10)

**Check:** user-visible changes have a CHANGELOG-worthy title. A release
change consists of exactly: `lib/eth/version.rb` bump + `CHANGELOG.md`
entry; tagging and `gem push` are human-only actions and never part of an
agent-prepared diff.
**Pass:** holds.

### A11. Specification synchronization (SPEC D5, §10)

**Check:** newly discovered defects gained SPEC §9 register entries; public
surface changes updated the matching `docs/spec/` contract; SPEC §4/§5 remain
uncontradicted by the change (drift check).
**Pass:** SPEC and code agree after the change.

## Part B — the specification framework itself

### B1. File inventory

**Check:** all of the following exist, each beginning with a 2-line SPDX
header (`SPDX-FileCopyrightText`, `SPDX-License-Identifier: Apache-2.0`) in
an HTML comment: `SPEC.md`, `ACCEPTANCE.md`, `CLAUDE.md`,
`docs/spec/01-foundations.md`, `docs/spec/02-keys-signatures.md`,
`docs/spec/03-abi.md`, `docs/spec/04-transactions.md`,
`docs/spec/05-client-rpc.md`, `docs/spec/06-contracts-ens-solidity.md`.
**Pass:** all nine present with headers.

### B2. Decisions confirmed

**Check:** SPEC §4 lists D1–D12, every one marked ✅ with the confirmation
date; SPEC header table says ACTIVE and names the baseline (v0.5.17,
commit `cedc60cc`).
**Pass:** holds.

### B3. Register integrity

**Check:** SPEC §9 lists R1–R17; every entry has an evidence anchor
(`file:line` or named source) and a disposition from the legend. Resolve
every **verified** anchor against the working tree and confirm the described
code is there (e.g. R3 → `lib/eth/rlp/encoder.rb:46` shows
`raise EncodingError "…"` with no comma; R8 → `lib/eth/tx/eip7702.rb:97-110`
shows `unsigned_encoded` RLP-encoding `[chain_id, address, nonce]` with no
`0x05` prefix byte).
**Pass:** all anchors resolve as described.

### B4. Domain coverage is total

**Check:** every Ruby file under `lib/` maps to exactly one `docs/spec/`
contract per SPEC §3, and each of these modules has a public-API inventory in
its contract: Constant, Unit, Util, Address, Chain, Rlp (+ Sedes), Key
(+ Encrypter, Decrypter), Signature, Eip712, Bls, Abi (+ Type, Encoder,
Decoder, Event, Function, Packed::Encoder), Tx (+ Legacy, Eip2930, Eip1559,
Eip4844, Eip7702 + Authorization), Client (+ Http, Ipc, Ws), Api, Contract
(+ Event, Function, FunctionInput, FunctionOutput, Initializer, Error), Ens
(+ Resolver, CoinType), Solidity, version.
**Pass:** no module missing, none double-homed.

### B5. Accuracy spot-check

**Check:** in each of the six domain contracts, pick at least three concrete
claims (a method signature, a default value, a constant, an error string, an
invariant) and verify them against `lib/` source. Any claim found false fails
this criterion — accuracy over completeness.
**Pass:** ≥ 18 checks, zero false claims.

### B6. Upstream neutrality (SPEC D2)

**Check:** no framework file references contributor-private workflow (branch
naming schemes, personal coverage policies, user-specific paths, private
tooling); tone and requirements are project-level only.
**Pass:** nothing private found.

### B7. No functional changes

**Command:** `git diff --name-only main...HEAD`
**Pass:** only documentation/framework files (`*.md`, `docs/**`, and — if
separately approved — `.claude/**`); zero changes under `lib/`, `spec/`,
`abi/`, `bin/`, or to `eth.gemspec`, `Gemfile`, `Rakefile`, CI workflows.

### B8. Link integrity

**Check:** every intra-repository link in the nine framework files resolves
to an existing file/anchor.
**Pass:** no dead links.

### B9. CLAUDE.md completeness

**Check:** CLAUDE.md contains, at minimum: the tiered test commands (as in
A2/A3, consistent with them); the architecture map or a pointer to SPEC §3;
the register-first workflow (D5) and compatibility rules (D4) in summary with
pointers; the security rules (D11) in summary; the release split (agents
prepare, humans publish, D10); and pointers to SPEC.md, ACCEPTANCE.md, and
docs/spec/.
**Pass:** all present and consistent with SPEC/ACCEPTANCE.

### B10. Self-check

**Check:** every Part A criterion above states a command or concrete
procedure plus an unambiguous pass condition, executable without any session
context.
**Pass:** holds.
