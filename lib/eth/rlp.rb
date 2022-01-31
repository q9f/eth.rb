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

require "eth/rlp/decoder"
require "eth/rlp/encoder"
require "eth/rlp/sedes"
require "eth/util"

# Provides the {Eth} module.
module Eth

  # Provides an recursive-length prefix (RLP) encoder and decoder.
  module Rlp
    extend self

    # The Rlp module exposes a variety of exceptions grouped as {RlpException}.
    class RlpException < StandardError; end

    # An error-type to point out RLP-encoding errors.
    class EncodingError < RlpException; end

    # An error-type to point out RLP-decoding errors.
    class DecodingError < RlpException; end

    # An error-type to point out RLP-type serialization errors.
    class SerializationError < RlpException; end

    # An error-type to point out RLP-type serialization errors.
    class DeserializationError < RlpException; end

    # A wrapper to represent already RLP-encoded data.
    class Data < String; end

    # Performes an {Eth::Rlp::Encoder} on any ruby object.
    #
    # @param obj [Object] any ruby object.
    # @return [String] a packed, RLP-encoded item.
    def encode(obj)
      Rlp::Encoder.perform obj
    end

    # Performes an {Eth::Rlp::Decoder} on any RLP-encoded item.
    #
    # @param rlp [String] a packed, RLP-encoded item.
    # @return [Object] a decoded ruby object.
    def decode(rlp)
      Rlp::Decoder.perform rlp
    end
  end
end
