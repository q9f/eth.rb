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
  module Abi
    extend self
    include Constant

    # Provides a special encoding error if anything fails to encode.
    class EncodingError < StandardError; end

    # Provides a special decoding error if anything fails to decode.
    class DecodingError < StandardError; end

    # Provides a special out-of-bounds error for values.
    class ValueOutOfBounds < StandardError; end

    # Encodes Application Binary Interface (ABI) data.
    #
    # @param types [Array] types to be ABI-encoded.
    # @param args [Array] values to be ABI-encoded.
    # @return [String] the encoded ABI data.
    def encode(types, args)
      parsed_types = types.map { |t| Type.parse(t) }
      head_size = (0...args.size)
        .map { |i| parsed_types[i].size or 32 }
        .reduce(0, &:+)
      head, tail = "", ""
      args.each_with_index do |arg, i|
        if parsed_types[i].is_dynamic?
          head += encode_type Type.size_type, head_size + tail.size
          tail += encode_type parsed_types[i], arg
        else
          head += encode_type parsed_types[i], arg
        end
      end
      "#{head}#{tail}"
    end

    # Encodes types.
    #
    # @param type [Eth::Abi::Type] type to be encoded.
    # @param arg [String, Number] value to be encoded.
    # @return [String] the encoded type.
    # @raise [ArgumentError] if value does not match type.
    def encode_type(type, arg)
      if %w(string bytes).include? type.base_type and type.sub_type.empty?
        raise ArgumentError, "arg must be a string" unless arg.instance_of? String
        size = encode_type Type.size_type, arg.size
        padding = BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)
        "#{size}#{arg}#{padding}"
      elsif type.is_dynamic?
        raise ArgumentError, "arg must be an array" unless arg.instance_of? Array
        head, tail = "", ""
        if type.dimensions.last == 0
          head += encode_type Type.size_type, arg.size
        else
          raise ArgumentError, "Wrong array size: found #{arg.size}, expecting #{type.dimensions.last}" unless arg.size == type.dimensions.last
        end
        nested_sub = type.nested_sub
        nested_sub_size = type.nested_sub.size
        arg.size.times do |i|
          if nested_sub_size.nil?
            head += encode_type Type.size_type, 32 * arg.size + tail.size
            tail += encode_type nested_sub, arg[i]
          else
            head += encode_type nested_sub, arg[i]
          end
        end
        "#{head}#{tail}"
      else
        if type.dimensions.empty?
          encode_primitive_type type, arg
        else
          arg.map { |x| encode_type(type.nested_sub, x) }.join
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
        real_size = type.sub_type.to_i
        i = get_uint arg
        raise ValueOutOfBounds, arg unless i >= 0 and i < 2 ** real_size
        Util.zpad_int i
      when "bool"
        raise ArgumentError, "arg is not bool: #{arg}" unless arg.instance_of? TrueClass or arg.instance_of? FalseClass
        Util.zpad_int(arg ? 1 : 0)
      when "int"
        real_size = type.sub_type.to_i
        i = get_int arg
        raise ValueOutOfBounds, arg unless i >= -2 ** (real_size - 1) and i < 2 ** (real_size - 1)
        Util.zpad_int(i % 2 ** type.sub_type.to_i)
      when "ureal", "ufixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        raise ValueOutOfBounds, arg unless arg >= 0 and arg < 2 ** high
        Util.zpad_int((arg * 2 ** low).to_i)
      when "real", "fixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        raise ValueOutOfBounds, arg unless arg >= -2 ** (high - 1) and arg < 2 ** (high - 1)
        i = (arg * 2 ** low).to_i
        Util.zpad_int(i % 2 ** (high + low))
      when "string", "bytes"
        raise EncodingError, "Expecting string: #{arg}" unless arg.instance_of? String
        if type.sub_type.empty?
          size = Util.zpad_int arg.size
          padding = BYTE_ZERO * (Util.ceil32(arg.size) - arg.size)
          "#{size}#{arg}#{padding}"
        else
          raise ValueOutOfBounds, arg unless arg.size <= type.sub_type.to_i
          padding = BYTE_ZERO * (32 - arg.size)
          "#{arg}#{padding}"
        end
      when "hash"
        size = type.sub_type.to_i
        raise EncodingError, "too long: #{arg}" unless size > 0 and size <= 32
        if arg.is_a? Integer
          Util.zpad_int arg
        elsif arg.size == size
          Util.zpad arg, 32
        elsif arg.size == size * 2
          Util.zpad_hex arg
        else
          raise EncodingError, "Could not parse hash: #{arg}"
        end
      when "address"
        if arg.is_a? Integer
          Util.zpad_int arg
        elsif arg.size == 20
          Util.zpad arg, 32
        elsif arg.size == 40
          Util.zpad_hex arg
        elsif arg.size == 42 and arg[0, 2] == "0x"
          Util.zpad_hex arg[2..-1]
        else
          raise EncodingError, "Could not parse address: #{arg}"
        end
      else
        raise EncodingError, "Unhandled type: #{type.base_type} #{type.sub_type}"
      end
    end

    # Decodes Application Binary Interface (ABI) data.
    #
    # @param types [Array] types describint the ABI to be decoded.
    # @param data [String] ABI data to be decoded.
    # @return [Array] the decoded ABI data.
    def decode(types, data)
      data = Eth::Util.hex_to_bin data if Eth::Util.is_hex? data
      parsed_types = types.map { |t| Type.parse(t) }
      outputs = [nil] * types.size
      start_positions = [nil] * types.size + [data.size]
      pos = 0
      parsed_types.each_with_index do |t, i|
        if t.is_dynamic?
          start_positions[i] = Util.deserialize_big_endian_to_int(data[pos, 32])
          j = i - 1
          while j >= 0 and start_positions[j].nil?
            start_positions[j] = start_positions[i]
            j -= 1
          end
          pos += 32
        else
          outputs[i] = data[pos, t.size]
          pos += t.size
        end
      end
      j = types.size - 1
      while j >= 0 and start_positions[j].nil?
        start_positions[j] = start_positions[types.size]
        j -= 1
      end
      raise DecodingError, "Not enough data for head" unless pos <= data.size
      parsed_types.each_with_index do |t, i|
        if t.is_dynamic?
          offset, next_offset = start_positions[i, 2]
          outputs[i] = data[offset...next_offset]
        end
      end
      parsed_types.zip(outputs).map { |(type, out)| decode_type(type, out) }
    end

    # Decodes types.
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
        data[0, l]
      elsif type.is_dynamic?
        l = Util.deserialize_big_endian_to_int arg[0, 32]
        nested_sub = type.nested_sub
        if nested_sub.is_dynamic?
          raise DecodingError, "Not enough data for head" unless arg.size >= 32 + 32 * l
          start_positions = (1..l).map { |i| Util.deserialize_big_endian_to_int arg[32 * i, 32] }
          start_positions.push arg.size
          outputs = (0...l).map { |i| arg[start_positions[i]...start_positions[i + 1]] }
          outputs.map { |out| decode_type(nested_sub, out) }
        else
          (0...l).map { |i| decode_type(nested_sub, arg[32 + nested_sub.size * i, nested_sub.size]) }
        end
      elsif !type.dimensions.empty?
        l = type.dimensions.last[0]
        nested_sub = type.nested_sub
        (0...l).map { |i| decode_type(nested_sub, arg[nested_sub.size * i, nested_sub.size]) }
      else
        decode_primitive_type type, arg
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
        "0x#{Util.bin_to_hex data[12..-1]}"
      when "string", "bytes"
        if type.sub_type.empty?
          size = Util.deserialize_big_endian_to_int data[0, 32]
          data[32..-1][0, size]
        else
          data[0, type.sub_type.to_i]
        end
      when "hash"
        data[(32 - type.sub_type.to_i), type.sub_type.to_i]
      when "uint"
        Util.deserialize_big_endian_to_int data
      when "int"
        u = Util.deserialize_big_endian_to_int data
        u >= 2 ** (type.sub_type.to_i - 1) ? (u - 2 ** type.sub_type.to_i) : u
      when "ureal", "ufixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        Util.deserialize_big_endian_to_int(data) * 1.0 / 2 ** low
      when "real", "fixed"
        high, low = type.sub_type.split("x").map(&:to_i)
        u = Util.deserialize_big_endian_to_int data
        i = u >= 2 ** (high + low - 1) ? (u - 2 ** (high + low)) : u
        i * 1.0 / 2 ** low
      when "bool"
        data[-1] == BYTE_ONE
      else
        raise DecodingError, "Unknown primitive type: #{type.base_type}"
      end
    end

    private

    def get_uint(n)
      case n
      when Integer
        raise EncodingError, "Number out of range: #{n}" if n > UINT_MAX or n < UINT_MIN
        n
      when String
        if n.size == 40
          Util.deserialize_big_endian_to_int Util.hex_to_bin n
        elsif n.size <= 32
          Util.deserialize_big_endian_to_int n
        else
          raise EncodingError, "String too long: #{n}"
        end
      when true
        1
      when false, nil
        0
      else
        raise EncodingError, "Cannot decode uint: #{n}"
      end
    end

    def get_int(n)
      case n
      when Integer
        raise EncodingError, "Number out of range: #{n}" if n > INT_MAX or n < INT_MIN
        n
      when String
        if n.size == 40
          i = Util.deserialize_big_endian_to_int Util.hex_to_bin n
        elsif n.size <= 32
          i = Util.deserialize_big_endian_to_int n
        else
          raise EncodingError, "String too long: #{n}"
        end
        i > INT_MAX ? (i - TT256) : i
      when true
        1
      when false, nil
        0
      else
        raise EncodingError, "Cannot decode int: #{n}"
      end
    end
  end
end
