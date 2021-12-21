# Copyright (c) 2016-2022 The Ruby-Eth Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -*- encoding : ascii-8bit -*-

require "eth/abi/constant"
require "eth/abi/type"

# Provides the `Eth` module.
module Eth

  # Provides a Ruby implementation of the Ethereum Applicatoin Binary Interface (ABI).
  # ref: https://docs.soliditylang.org/en/develop/abi-spec.html
  module Abi
    extend self
    include Constant

    # Provides a special encoding error if anything fails to encode.
    class EncodingError < StandardError; end

    # Provides a special decoding error if anything fails to decode.
    class DecodingError < StandardError; end

    # Provides a special out-of-bounds error for values.
    class ValueOutOfBounds < StandardError; end

    # Encodes Application Binary Interface (ABI) data. It accepts multiple
    # arguments and encodes using the head/tail mechanism.
    #
    # @param types [Array] types to be ABI-encoded.
    # @param args [Array] values to be ABI-encoded.
    # @return [String] the encoded ABI data.
    def encode(types, args)

      # prase all types
      parsed_types = types.map { |t| Type.parse(t) }

      # prepare the "head"
      head_size = (0...args.size)
        .map { |i| parsed_types[i].size or 32 }
        .reduce(0, &:+)
      head, tail = "", ""

      # encode types and arguments
      args.each_with_index do |arg, i|
        if parsed_types[i].is_dynamic?
          head += encode_type Type.size_type, head_size + tail.size
          tail += encode_type parsed_types[i], arg
        else
          head += encode_type parsed_types[i], arg
        end
      end

      # return the encoded ABI blob
      return "#{head}#{tail}"
    end

    # Encodes a specific value, either static or dynamic.
    #
    # @param type [Eth::Abi::Type] type to be encoded.
    # @param arg [String, Number] value to be encoded.
    # @return [String] the encoded type.
    # @raise [ArgumentError] if value does not match type.
    def encode_type(type, arg)
      if %w(string bytes).include? type.base_type and type.sub_type.empty?
        raise ArgumentError, "Argument must be a String" unless arg.instance_of? String

        # encodes strings and bytes
        size = encode_type Type.size_type, arg.size
        padding = BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)
        return "#{size}#{arg}#{padding}"
      elsif type.is_dynamic?
        raise ArgumentError, "Argument must be an Array" unless arg.instance_of? Array

        # encodes dynamic-sized arrays
        head, tail = "", ""
        head += encode_type Type.size_type, arg.size
        nested_sub = type.nested_sub
        nested_sub_size = type.nested_sub.size
        arg.size.times do |i|
          raise NotImplementedError, "Encoding dynamic arrays with nested dynamic sub-types is not implemented for ABI." if nested_sub.is_dynamic?
          head += encode_type nested_sub, arg[i]
        end
        return "#{head}#{tail}"
      else
        if type.dimensions.empty?

          # encode a primitive type
          return encode_primitive_type type, arg
        else

          # encode static-size arrays
          return arg.map { |x| encode_type(type.nested_sub, x) }.join
        end
      end
    end

    # Encodes primitive types.
    #
    # @param type [Eth::Abi::Type] type to be encoded.
    # @param arg [String, Number] value to be encoded.
    # @return [String] the encoded primitive type.
    # @raise [ArgumentError] if value does not match type.
    # @raise [ValueOutOfBounds] if value is out of bounds for type.
    # @raise [EncodingError] if encoding fails for type.
    def encode_primitive_type(type, arg)
      case type.base_type
      when "uint"
        raise ValueOutOfBounds, "Number out of range: #{arg}" if arg > UINT_MAX or arg < UINT_MIN
        real_size = type.sub_type.to_i
        i = arg.to_i
        raise ValueOutOfBounds, arg unless i >= 0 and i < 2 ** real_size

        # unsigned integer numerics
        return Util.zpad_int i
      when "bool"
        raise ArgumentError, "Argument is not bool: #{arg}" unless arg.instance_of? TrueClass or arg.instance_of? FalseClass

        # booleans
        return Util.zpad_int(arg ? 1 : 0)
      when "int"
        raise ValueOutOfBounds, "Number out of range: #{arg}" if arg > INT_MAX or arg < INT_MIN
        real_size = type.sub_type.to_i
        i = arg.to_i
        raise ValueOutOfBounds, arg unless i >= -2 ** (real_size - 1) and i < 2 ** (real_size - 1)

        # integer numerics
        return Util.zpad_int(i % 2 ** type.sub_type.to_i)
      when "ureal", "ufixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        raise ValueOutOfBounds, arg unless arg >= 0 and arg < 2 ** high

        # unsigned fixed point numerics
        return Util.zpad_int((arg * 2 ** low).to_i)
      when "real", "fixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        raise ValueOutOfBounds, arg unless arg >= -2 ** (high - 1) and arg < 2 ** (high - 1)
        i = (arg * 2 ** low).to_i

        # fixed point numerics
        return Util.zpad_int(i % 2 ** (high + low))
      when "string", "bytes"
        raise EncodingError, "Expecting String: #{arg}" unless arg.instance_of? String
        if type.sub_type.empty?
          size = Util.zpad_int arg.size
          padding = BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)

          # variable length string/bytes
          return "#{size}#{arg}#{padding}"
        else
          raise ValueOutOfBounds, arg unless arg.size <= type.sub_type.to_i
          padding = BYTE_ZERO * (32 - arg.size)

          # fixed length string/bytes
          return "#{arg}#{padding}"
        end
      when "hash"
        size = type.sub_type.to_i
        raise EncodingError, "Argument too long: #{arg}" unless size > 0 and size <= 32
        if arg.is_a? Integer

          # hash from integer
          return Util.zpad_int arg
        elsif arg.size == size

          # hash from encoded hash
          return Util.zpad arg, 32
        elsif arg.size == size * 2

          # hash from hexa-decimal hash
          return Util.zpad_hex arg
        else
          raise EncodingError, "Could not parse hash: #{arg}"
        end
      when "address"
        if arg.is_a? Integer

          # address from integer
          return Util.zpad_int arg
        elsif arg.size == 20

          # address from encoded address
          return Util.zpad arg, 32
        elsif arg.size == 40

          # address from hexa-decimal address with 0x prefix
          return Util.zpad_hex arg
        elsif arg.size == 42 and arg[0, 2] == "0x"

          # address from hexa-decimal address
          return Util.zpad_hex arg[2..-1]
        else
          raise EncodingError, "Could not parse address: #{arg}"
        end
      else
        raise EncodingError, "Unhandled type: #{type.base_type} #{type.sub_type}"
      end
    end

    # Decodes Application Binary Interface (ABI) data. It accepts multiple
    # arguments and decodes using the head/tail mechanism.
    #
    # @param types [Array] the ABI to be decoded.
    # @param data [String] ABI data to be decoded.
    # @return [Array] the decoded ABI data.
    def decode(types, data)

      # accept hex abi but decode it first
      data = Util.hex_to_bin data if Util.is_hex? data

      # parse all types
      parsed_types = types.map { |t| Type.parse(t) }

      # prepare output data
      outputs = [nil] * types.size
      start_positions = [nil] * types.size + [data.size]
      pos = 0
      parsed_types.each_with_index do |t, i|
        if t.is_dynamic?

          # record start position for dynamic type
          start_positions[i] = Util.deserialize_big_endian_to_int(data[pos, 32])
          j = i - 1
          while j >= 0 and start_positions[j].nil?
            start_positions[j] = start_positions[i]
            j -= 1
          end
          pos += 32
        else

          # get data directly for static types
          outputs[i] = data[pos, t.size]
          pos += t.size
        end
      end

      # add start position equal the length of the entire data
      j = types.size - 1
      while j >= 0 and start_positions[j].nil?
        start_positions[j] = start_positions[types.size]
        j -= 1
      end
      raise DecodingError, "Not enough data for head" unless pos <= data.size

      # add dynamic types
      parsed_types.each_with_index do |t, i|
        if t.is_dynamic?
          offset, next_offset = start_positions[i, 2]
          outputs[i] = data[offset...next_offset]
        end
      end

      # return the decoded ABI types and data
      return parsed_types.zip(outputs).map { |(type, out)| decode_type(type, out) }
    end

    # Decodes a specific value, either static or dynamic.
    #
    # @param type [Eth::Abi::Type] type to be decoded.
    # @param arg [String] encoded type data string.
    # @return [String] the decoded data for the type.
    # @raise [DecodingError] if decoding fails for type.
    def decode_type(type, arg)
      if %w(string bytes).include?(type.base_type) and type.sub_type.empty?
        l = Util.deserialize_big_endian_to_int arg[0, 32]
        data = arg[32..-1]
        raise DecodingError, "Wrong data size for string/bytes object" unless data.size == Util.ceil32(l)

        # decoded strings and bytes
        return data[0, l]
      elsif type.is_dynamic?
        l = Util.deserialize_big_endian_to_int arg[0, 32]
        nested_sub = type.nested_sub
        raise NotImplementedError, "Decoding dynamic arrays with nested dynamic sub-types is not implemented for ABI." if nested_sub.is_dynamic?

        # decoded dynamic-sized arrays
        return (0...l).map { |i| decode_type(nested_sub, arg[32 + nested_sub.size * i, nested_sub.size]) }
      elsif !type.dimensions.empty?
        l = type.dimensions.last[0]
        nested_sub = type.nested_sub

        # decoded static-size arrays
        return (0...l).map { |i| decode_type(nested_sub, arg[nested_sub.size * i, nested_sub.size]) }
      else

        # decoded primitive types
        return decode_primitive_type type, arg
      end
    end

    # Decodes primitive types.
    #
    # @param type [Eth::Abi::Type] type to be decoded.
    # @param data [String] encoded primitive type data string.
    # @return [String] the decoded data for the type.
    # @raise [DecodingError] if decoding fails for type.
    def decode_primitive_type(type, data)
      case type.base_type
      when "address"

        # decoded address with 0x-prefix
        return "0x#{Util.bin_to_hex data[12..-1]}"
      when "string", "bytes"
        if type.sub_type.empty?
          size = Util.deserialize_big_endian_to_int data[0, 32]

          # decoded dynamic-sized array
          return data[32..-1][0, size]
        else

          # decoded static-sized array
          return data[0, type.sub_type.to_i]
        end
      when "hash"

        # decoded hash
        return data[(32 - type.sub_type.to_i), type.sub_type.to_i]
      when "uint"

        # decoded unsigned integer
        return Util.deserialize_big_endian_to_int data
      when "int"
        u = Util.deserialize_big_endian_to_int data
        i = u >= 2 ** (type.sub_type.to_i - 1) ? (u - 2 ** type.sub_type.to_i) : u

        # decoded integer
        return i
      when "ureal", "ufixed"
        high, low = type.sub_type.split("x").map(&:to_i)

        # decoded unsigned fixed point numeric
        return Util.deserialize_big_endian_to_int(data) * 1.0 / 2 ** low
      when "real", "fixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        u = Util.deserialize_big_endian_to_int data
        i = u >= 2 ** (high + low - 1) ? (u - 2 ** (high + low)) : u

        # decoded fixed point numeric
        return i * 1.0 / 2 ** low
      when "bool"

        # decoded boolean
        return data[-1] == BYTE_ONE
      else
        raise DecodingError, "Unknown primitive type: #{type.base_type}"
      end
    end
  end
end
