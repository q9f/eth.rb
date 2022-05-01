module Eth
  class Contract::Abi
    def self.parse_abi(abi)
      constructor = abi.detect {|x| x["type"] == "constructor"}
      if !constructor.nil?
        constructor_inputs = constructor["inputs"].map { |input| Eth::Contract::FunctionInput.new(input) }
      else
        constructor_inputs = []
      end
      functions = abi.select {|x| x["type"] == "function" }.map { |fun| Eth::Contract::Function.new(fun) }
      events = abi.select {|x| x["type"] == "event" }.map { |evt| Eth::Contract::Event.new(evt) }
      [constructor_inputs, functions, events]
    end
  end
end
