# Copyright (c) 2016-2023 The Ruby-Eth Contributors
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
    # @param packed [Boolean] use custom packed encoding (default: false).
    # @return [String] the encoded ABI data.
    def encode(types, args, packed = false)

      # parse all types
      parsed_types = types.map { |t| Type === t ? t : Type.parse(t) }

      # prepare the "head"
      head_size = (0...args.size)
        .map { |i|
        if packed
          parsed_types[i].sub_type.to_i / 8
        else
          parsed_types[i].size or 32
        end
      }
        .reduce(0, &:+)
      head, tail = "", ""

      # encode types and arguments
      args.each_with_index do |arg, i|
        if packed
          head += Abi::Encoder.type(parsed_types[i], arg, packed)
        elsif parsed_types[i].dynamic?
          head += Abi::Encoder.type(Type.size_type, head_size + tail.size, packed)
          tail += Abi::Encoder.type(parsed_types[i], arg, packed)
        else
          head += Abi::Encoder.type(parsed_types[i], arg, packed)
        end
      end

      if tail.size == 0 && packed
        tail = head
      end

      # return the encoded ABI blob
      packed ? "#{tail}" : "#{head}#{tail}"
    end

    # Encodes a custom, packed Application Binary Interface (packed ABI) data.
    # It accepts multiple arguments and encodes according to the Solidity specification.
    #
    # @param types [Array] types to be ABI-encoded.
    # @param args [Array] values to be ABI-encoded.
    # @return [String] the packed encoded ABI data.
    def encode_packed(types, args)
      encode(types, args, true)
    end

    # Decodes Application Binary Interface (ABI) data. It accepts multiple
    # arguments and decodes using the head/tail mechanism.
    #
    # @param types [Array] the ABI to be decoded.
    # @param data [String] ABI data to be decoded.
    # @param packed [Boolean] use custom packed decoding.
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
      parsed_types.zip(outputs).map { |(type, out)| Abi::Decoder.type(type, out, packed) }
    end

    # Since the encoding is ambiguous, there is no decoding function.
    #
    # @param types [Array] the ABI to be decoded.
    # @param data [String] ABI data to be decoded.
    # @raise [DecodingError] if you try to decode packed ABI data.
    def decode_packed(types, data)
      raise DecodingError, "Since the encoding is ambiguous, there is no decoding function."
    end
  end
end

require "eth/abi/decoder"
require "eth/abi/encoder"
require "eth/abi/event"
require "eth/abi/type"
