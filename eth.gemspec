# frozen_string_literal: true
# coding: utf-8

lib = File.expand_path('lib', __dir__).freeze
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'eth'

Gem::Specification.new do |spec|
  spec.name          = "eth"
  spec.version       = Eth::VERSION
  spec.authors       = ["Steve Ellis", "Afri Schoedon"]
  spec.email         = ["email@steveell.is", "ruby@q9f.cc"]

  spec.summary       = %q{Library to handle Ethereum accounts, messages, and transactions.}
  spec.description   = %q{Library to handle Ethereum accounts, messages, and transactions.}
  spec.homepage      = "https://github.com/q9f/eth.rb"
  spec.license       = "Apache-2.0"

  spec.metadata = {
    'homepage_uri'    => 'https://github.com/q9f/eth.rb',
    'source_code_uri' => 'https://github.com/q9f/eth.rb',
    'github_repo'     => 'https://github.com/q9f/eth.rb',
    'bug_tracker_uri' => 'https://github.com/q9f/eth.rb/issues',
  }.freeze

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.test_files    = spec.files.grep %r{^(test|spec|features)/}

  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 2.6", "< 4.0"

  spec.add_dependency 'rbsecp256k1', '~> 5.0'

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
end
