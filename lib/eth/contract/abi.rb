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

    def self.parse_type(type)
      raise NotImplementedError if type.ends_with?("]")
      match = /(\D+)(\d.*)?/.match(type)
      [match[1], match[2]]
    end

    def self.parse_array_type(type)
      match = /(.+)\[(\d*)\]\z/.match(type)
      if match
        [true, match[2].present? ? match[2].to_i : nil, match[1]]
      else
        [false, nil, nil]
      end
    end
  end
end
