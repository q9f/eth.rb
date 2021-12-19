
# Provides the `Eth` module.
module Eth

  # Provides a Ruby implementation of the Ethereum Applicatoin Binary Interface (ABI).
  module Abi

#     class Type
#       class ParseError < StandardError; end
#       class <<self
#         def parse(type)
#           _, base, sub, dimension = /([a-z]*)([0-9]*x?[0-9]*)((\[[0-9]*\])*)/.match(type).to_a

#           dims = dimension.scan(/\[[0-9]*\]/)
#           raise ParseError, "Unknown characters found in array declaration" if dims.join != dimension

#           case base
#           when 'string'
#             raise ParseError, "String type must have no suffix or numerical suffix" unless sub.empty?
#           when 'bytes'
#             raise ParseError, "Maximum 32 bytes for fixed-length string or bytes" unless sub.empty? || sub.to_i <= 32
#           when 'uint', 'int'
#             raise ParseError, "Integer type must have numerical suffix" unless sub =~ /\A[0-9]+\z/

#             size = sub.to_i
#             raise ParseError, "Integer size out of bounds" unless size >= 8 && size <= 256
#             raise ParseError, "Integer size must be multiple of 8" unless size % 8 == 0
#           when 'ureal', 'real', 'fixed', 'ufixed'
#             raise ParseError, "Real type must have suffix of form <high>x<low>, e.g. 128x128" unless sub =~ /\A[0-9]+x[0-9]+\z/

#             high, low = sub.split('x').map(&:to_i)
#             total = high + low

#             raise ParseError, "Real size out of bounds (max 32 bytes)" unless total >= 8 && total <= 256
#             raise ParseError, "Real high/low sizes must be multiples of 8" unless high % 8 == 0 && low % 8 == 0
#           when 'hash'
#             raise ParseError, "Hash type must have numerical suffix" unless sub =~ /\A[0-9]+\z/
#           when 'address'
#             raise ParseError, "Address cannot have suffix" unless sub.empty?
#           when 'bool'
#             raise ParseError, "Bool cannot have suffix" unless sub.empty?
#           else
#           end

#           new(base, sub, dims.map {|x| x[1...-1].to_i })
#         end

#         def size_type
#           @size_type ||= new('uint', 256, [])
#         end
#       end

#       attr :base, :sub, :dims

#       def initialize(base, sub, dims)
#         @base = base
#         @sub  = sub
#         @dims = dims
#       end

#       def ==(another_type)
#         base == another_type.base &&
#           sub == another_type.sub &&
#           dims == another_type.dims
#       end

#       def size
#         @size ||= if dims.empty?
#                     if %w(string bytes).include?(base) && sub.empty?
#                       nil
#                     else
#                       32
#                     end
#                   else
#                       nil
#                     else
#                       subtype.dynamic? ? nil : dims.last * subtype.size
#                     end
#                   end
#       end

#       def dynamic?
#         size.nil?
#       end

#       def subtype
#         @subtype ||= self.class.new(base, sub, dims[0...-1])
#       end
#     end
  end
end
