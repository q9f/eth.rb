$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "eth"
require "json"
RSpec.configure do |config|
end
