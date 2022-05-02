module Eth
  class Contract::FunctionOutput
    attr_accessor :type, :name

    def initialize(data)
      @type = Eth::Abi::Type.parse(data["type"])
      @name = data["name"]
    end

    def type
      @type.base_type + @type.sub_type
    end
  end
end
