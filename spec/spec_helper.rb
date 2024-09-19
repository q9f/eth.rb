# use the local version of the code instead of a globally installed gem
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

# only run coverage reports on github actions
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

include Eth

shared_examples "an ABI type implementing the Meta interface" do
  it { is_expected.to respond_to(:size) }
  it { is_expected.to respond_to(:format) }
end
