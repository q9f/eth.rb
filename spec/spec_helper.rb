# use the local version of the code instead of a globally installed gem
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

if ENV["COVERAGE"] or ENV["CI"]
  require "simplecov"
  require "simplecov-cobertura"
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  SimpleCov.start
end

require "eth"
require "json"
RSpec.configure do |config|
end

include Eth
