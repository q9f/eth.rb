require_relative 'types/num'
require_relative 'types/bin'
require_relative 'types/hex'
require_relative 'types/dec'

module TypeShortcuts
  def Num
    Eth::Types::Num.new
  end

  def Hex(str)
    Eth::Types::Hex.new(str)
  end

  def Dec(str)
    Eth::Types::Dec.new(str)
  end

  def Bin(str)
    Eth::Types::Bin.new(str)
  end
end

Eth::Types::Num.superclass.extend(TypeShortcuts)

