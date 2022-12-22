# Contributing to Ruby Ethereum

Everyone is welcome to contribute to the Ruby Ethereum gem. It is
more than six years old and had seen many maintainers come and go.

Current maintainers:
* [@q9f](https://github.com/q9f)
* [@kurotaky](https://github.com/kurotaky)

### Workflow

To propose a change, fix, or new feature, create an issue or comment
on an existing issue to see if anyone else has an opinion on it or is
eventually already working on it

The general workflow looks roughly like this:

1. Discuss it
2. Fork it
3. Improve it
4. Test it
5. Document it
6. Submit it

### Linting

We use the Ruby formatter `rufo` to ensure consistent formatting across
the code base.
* <https://github.com/ruby-formatter/rufo>

Simply run `rufo .` before comitting your changes.

### Testing

We use behaviour-driven development and this codebase is at least 100%
unit tested. We use RSpec to run the spec tests.
* <https://rspec.info>

The full Ethereum test-suite is available in `fixtures/ethereum/tests`.
Run `git submodule update --init --recursive` to fetch it.
* <https://github.com/ethereum/tests>

If your tests are failing make sure you pulled the ethereum/tests 
submodule and run a local geth node in background with
`geth --dev --http --ipcpath /tmp/geth.ipc` as we are running some tests
against a local live node.

Other static test data is available in `fixtures/`

### Documentation

We use the Ruby documentation tool Yard.
* <https://yardoc.org>

The code base is 100% API documented.
* <https://q9f.github.io/eth.rb>

More involved documentation, tutorials, and usage examples should go
into the wiki.
* <https://github.com/q9f/eth.rb/wiki>

