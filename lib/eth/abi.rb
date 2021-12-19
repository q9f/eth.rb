require 'eth/abi/constant'
# require 'eth/abi/type'

module Eth
  module Abi
    extend self
    include Constant
#     class EncodingError < StandardError; end
#     class DecodingError < StandardError; end
#     class ValueOutOfBounds < StandardError; end

#     def encode_abi(types, args)
#       parsed_types = types.map {|t| Type.parse(t) }

#       head_size = (0...args.size)
#         .map {|i| parsed_types[i].size || 32 }
#         .reduce(0, &:+)

#       head, tail = '', ''
#       args.each_with_index do |arg, i|
#         if parsed_types[i].dynamic?
#           head += encode_type(Type.size_type, head_size + tail.size)
#           tail += encode_type(parsed_types[i], arg)
#         else
#           head += encode_type(parsed_types[i], arg)
#         end
#       end

#     end
#     alias :encode :encode_abi

#     def encode_type(type, arg)
#       if %w(string bytes).include?(type.base) && type.sub.empty?
#         raise ArgumentError, "arg must be a string" unless arg.instance_of?(String)

#         size = encode_type Type.size_type, arg.size
#         padding = BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)

#       elsif type.dynamic?
#         raise ArgumentError, "arg must be an array" unless arg.instance_of?(Array)

#         head, tail = '', ''
#         if type.dims.last == 0
#           head += encode_type(Type.size_type, arg.size)
#         else
#         end

#         sub_type = type.subtype
#         sub_size = type.subtype.size
#         arg.size.times do |i|
#           if sub_size.nil?
#             head += encode_type(Type.size_type, 32*arg.size + tail.size)
#             tail += encode_type(sub_type, arg[i])
#           else
#             head += encode_type(sub_type, arg[i])
#           end
#         end

#         if type.dims.empty?
#           encode_primitive_type type, arg
#         else
#           arg.map {|x| encode_type(type.subtype, x) }.join
#         end
#       end
#     end

#     def encode_primitive_type(type, arg)
#       case type.base
#       when 'uint'
#         real_size = type.sub.to_i
#         i = get_uint arg

#         raise ValueOutOfBounds, arg unless i >= 0 && i < 2**real_size
#         Util.zpad_int i
#       when 'bool'
#         Util.zpad_int(arg ? 1: 0)
#       when 'int'
#         real_size = type.sub.to_i
#         i = get_int arg

#         raise ValueOutOfBounds, arg unless i >= -2**(real_size-1) && i < 2**(real_size-1)
#         Util.zpad_int(i % 2**type.sub.to_i)
#       when 'ureal', 'ufixed'
#         high, low = type.sub.split('x').map(&:to_i)

#         raise ValueOutOfBounds, arg unless arg >= 0 && arg < 2**high
#         Util.zpad_int((arg * 2**low).to_i)
#       when 'real', 'fixed'
#         high, low = type.sub.split('x').map(&:to_i)

#         raise ValueOutOfBounds, arg unless arg >= -2**(high - 1) && arg < 2**(high - 1)

#         i = (arg * 2**low).to_i
#         Util.zpad_int(i % 2**(high+low))
#       when 'string', 'bytes'

#           size = Util.zpad_int arg.size
#           padding = BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)
#           raise ValueOutOfBounds, arg unless arg.size <= type.sub.to_i

#           padding = BYTE_ZERO * (32 - arg.size)
#         end
#       when 'hash'
#         size = type.sub.to_i

#         if arg.is_a?(Integer)
#           Util.zpad_int(arg)
#         elsif arg.size == size
#           Util.zpad arg, 32
#         elsif arg.size == size * 2
#           Util.zpad_hex arg
#         else
#         end
#       when 'address'
#         if arg.is_a?(Integer)
#           Util.zpad_int arg
#         elsif arg.size == 20
#           Util.zpad arg, 32
#         elsif arg.size == 40
#           Util.zpad_hex arg
#         elsif arg.size == 42 && arg[0,2] == '0x'
#           Util.zpad_hex arg[2..-1]
#         else
#         end
#       else
#       end
#     end

#     def decode_abi(types, data)
#       parsed_types = types.map {|t| Type.parse(t) }

#       outputs = [nil] * types.size
#       start_positions = [nil] * types.size + [data.size]

#       pos = 0
#       parsed_types.each_with_index do |t, i|
#         if t.dynamic?
#           start_positions[i] = Util.deserialize_big_endian_to_int(data[pos, 32])

#           j = i - 1
#           while j >= 0 && start_positions[j].nil?
#             start_positions[j] = start_positions[i]
#             j -= 1
#           end

#           pos += 32
#         else
#           outputs[i] = data[pos, t.size]
#           pos += t.size
#         end
#       end

#       j = types.size - 1
#       while j >= 0 && start_positions[j].nil?
#         start_positions[j] = start_positions[types.size]
#         j -= 1
#       end

#       raise DecodingError, "Not enough data for head" unless pos <= data.size

#       parsed_types.each_with_index do |t, i|
#         if t.dynamic?
#           offset, next_offset = start_positions[i, 2]
#           outputs[i] = data[offset...next_offset]
#         end
#       end

#       parsed_types.zip(outputs).map {|(type, out)| decode_type(type, out) }
#     end
#     alias :decode :decode_abi

#     def decode_type(type, arg)
#       if %w(string bytes).include?(type.base) && type.sub.empty?
#         l = Util.deserialize_big_endian_to_int arg[0,32]
#         data = arg[32..-1]

#         raise DecodingError, "Wrong data size for string/bytes object" unless data.size == Util.ceil32(l)

#         data[0, l]
#       elsif type.dynamic?
#         l = Util.deserialize_big_endian_to_int arg[0,32]
#         subtype = type.subtype

#         if subtype.dynamic?
#           raise DecodingError, "Not enough data for head" unless arg.size >= 32 + 32*l

#           start_positions = (1..l).map {|i| Util.deserialize_big_endian_to_int arg[32*i, 32] }
#           start_positions.push arg.size

#           outputs = (0...l).map {|i| arg[start_positions[i]...start_positions[i+1]] }

#           outputs.map {|out| decode_type(subtype, out) }
#         else
#           (0...l).map {|i| decode_type(subtype, arg[32 + subtype.size*i, subtype.size]) }
#         end
#         l = type.dims.last[0]
#         subtype = type.subtype

#         (0...l).map {|i| decode_type(subtype, arg[subtype.size*i, subtype.size]) }
#       else
#         decode_primitive_type type, arg
#       end
#     end

#     def decode_primitive_type(type, data)
#       case type.base
#       when 'address'
#         Util.bin_to_hex data[12..-1]
#       when 'string', 'bytes'
#           size = Util.deserialize_big_endian_to_int data[0,32]
#           data[32..-1][0,size]
#           data[0, type.sub.to_i]
#         end
#       when 'hash'
#         data[(32 - type.sub.to_i), type.sub.to_i]
#       when 'uint'
#         Util.deserialize_big_endian_to_int data
#       when 'int'
#         u = Util.deserialize_big_endian_to_int data
#         u >= 2**(type.sub.to_i-1) ? (u - 2**type.sub.to_i) : u
#       when 'ureal', 'ufixed'
#         high, low = type.sub.split('x').map(&:to_i)
#         Util.deserialize_big_endian_to_int(data) * 1.0 / 2**low
#       when 'real', 'fixed'
#         high, low = type.sub.split('x').map(&:to_i)
#         u = Util.deserialize_big_endian_to_int data
#         i = u >= 2**(high+low-1) ? (u - 2**(high+low)) : u
#         i * 1.0 / 2**low
#       when 'bool'
#         data[-1] == BYTE_ONE
#       else
#       end
#     end

#     private

#     def get_uint(n)
#       case n
#       when Integer
#         n
#       when String
#         if n.size == 40
#           Util.deserialize_big_endian_to_int Util.hex_to_bin(n)
#         elsif n.size <= 32
#           Util.deserialize_big_endian_to_int n
#         else
#         end
#       when true
#         1
#       when false, nil
#         0
#       else
#       end
#     end

#     def get_int(n)
#       case n
#       when Integer
#         n
#       when String
#         if n.size == 40
#           i = Util.deserialize_big_endian_to_int Util.hex_to_bin(n)
#         elsif n.size <= 32
#           i = Util.deserialize_big_endian_to_int n
#         else
#         end
#         i > INT_MAX ? (i-TT256) : i
#       when true
#         1
#       when false, nil
#         0
#       else
#       end
#     end

  end
end
