# Copyright (c) 2016-2025 The Ruby-Eth Contributors
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

require "konstructor"

# Provides the {Eth} module.
module Eth

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
  # ref: https://docs.soliditylang.org/en/develop/abi-spec.html
  module Abi
    extend self

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
    # @param packed [Bool] set true to return packed encoding (default: `false`).
    # @return [String] the encoded ABI data.
    def encode(types, args, packed = false)
      return solidity_packed(types, args) if packed
      types = [types] unless types.instance_of? Array
      args = [args] unless args.instance_of? Array

      # parse all types
      parsed_types = types.map { |t| Type === t ? t : Type.parse(t) }

      # prepare the "head"
      head_size = (0...args.size)
        .map { |i| parsed_types[i].size or 32 }
        .reduce(0, &:+)
      head, tail = "", ""

      # encode types and arguments
      args.each_with_index do |arg, i|
        if parsed_types[i].dynamic?
          head += Abi::Encoder.type(Type.size_type, head_size + tail.size)
          tail += Abi::Encoder.type(parsed_types[i], arg)
        else
          head += Abi::Encoder.type(parsed_types[i], arg)
        end
      end

      # return the encoded ABI blob
      "#{head}#{tail}"
    end

    # Encodes Application Binary Interface (ABI) data in non-standard packed mode.
    # It accepts multiple arguments and encodes using the head/tail mechanism.
    #
    # @param types [Array] types to be ABI-encoded.
    # @param args [Array] values to be ABI-encoded.
    # @return [String] the encoded packed ABI data.
    # @raise [ArgumentError] if types and args are of different size.
    def solidity_packed(types, args)
      raise ArgumentError, "Types and values must be the same length" if types.length != args.length

      # We do not use the type system for packed encoding but want to call the parser once
      # to enforce the type validation.
      _ = types.map { |t| Type === t ? t : Type.parse(t) }

      packed = types.zip(args).map do |type, arg|
        Abi::Packed::Encoder.type(type, arg)
      end.join
      packed.force_encoding(Encoding::ASCII_8BIT)
    end

    # Decodes Application Binary Interface (ABI) data. It accepts multiple
    # arguments and decodes using the head/tail mechanism.
    #
    # @param types [Array] the ABI to be decoded.
    # @param data [String] ABI data to be decoded.
    # @return [Array] the decoded ABI data.
    def decode(types, data)

      # accept hex abi but decode it first
      data = Util.hex_to_bin data if Util.hex? data

      # parse all types
      parsed_types = types.map { |t| Type.parse(t) }

      # prepare output data
      outputs = [nil] * types.size
      start_positions = [nil] * types.size + [data.size]
      pos = 0
      parsed_types.each_with_index do |t, i|
        if t.dynamic?

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
        if t.dynamic?
          offset, next_offset = start_positions[i, 2]
          outputs[i] = data[offset...next_offset]
        end
      end

      # return the decoded ABI types and data
      parsed_types.zip(outputs).map { |(type, out)| Abi::Decoder.type(type, out) }
    end
  end
end

require "eth/abi/packed/encoder"
require "eth/abi/decoder"
require "eth/abi/encoder"
require "eth/abi/event"
require "eth/abi/type"
