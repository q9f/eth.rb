module Eth
  class Contract::Function

    attr_accessor :name, :inputs, :outputs, :signature, :constant, :function_string

    def initialize(data)
      @name = data["name"]
      @constant = data["constant"]
      @inputs = data["inputs"].map do |input|
        Eth::Contract::FunctionInput.new(input)
      end
      @outputs = data["outputs"].collect do |output|
        Eth::Contract::FunctionOutput.new(output)
      end
      @function_string = self.class.calc_signature(@name, @inputs)
      @signature = self.class.calc_id(@function_string)
    end

    def self.calc_signature(name, inputs)
      "#{name}(#{inputs.collect {|x| x.type }.join(",")})"
    end

    def self.calc_id(signature)
      Digest::Keccak.hexdigest(signature, 256)[0..7]
    end
  end
end
