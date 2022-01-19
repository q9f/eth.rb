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

# Provides the `Eth` module.
module Eth
  module Error
    class RlpException < StandardError; end

    class EncodingError < RlpException
      attr :obj

      def initialize(message, obj)
        super(message)
        @obj = obj
      end
    end

    class DecodingError < RlpException
      attr :rlp

      def initialize(message, rlp)
        super(message)
        @rlp = rlp
      end
    end

    class SerializationError < RlpException
      attr :obj

      def initialize(message, obj)
        super(message)
        @obj = obj
      end
    end

    class DeserializationError < RlpException
      attr :serial

      def initialize(message, serial)
        super(message)
        @serial = serial
      end
    end

    class ListSerializationError < SerializationError
      attr :index, :element_exception

      def initialize(message: nil, obj: nil, element_exception: nil, index: nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = "Serialization failed because of element at index #{index} ('#{element_exception}')"
        end
        super(message, obj)
        @index = index
        @element_exception = element_exception
      end
    end

    class ListDeserializationError < DeserializationError
      attr :index, :element_exception

      def initialize(message: nil, serial: nil, element_exception: nil, index: nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = "Deserialization failed because of element at index #{index} ('#{element_exception}')"
        end
        super(message, serial)
        @index = index
        @element_exception = element_exception
      end
    end

    class ObjectSerializationError < SerializationError
      attr :field, :list_exception

      def initialize(message: nil, obj: nil, sedes: nil, list_exception: nil)
        if message.nil?
          raise ArgumentError, "list_exception and sedes must be present" if list_exception.nil? || sedes.nil?
          if list_exception.element_exception
            field = sedes.serializable_fields.keys[list_exception.index]
            message = "Serialization failed because of field #{field} ('#{list_exception.element_exception}')"
          else
            field = nil
            message = "Serialization failed because of underlying list ('#{list_exception}')"
          end
        else
          field = nil
        end
        super(message, obj)
        @field = field
        @list_exception = list_exception
      end
    end

    class ObjectDeserializationError < DeserializationError
      attr :sedes, :field, :list_exception

      def initialize(message: nil, serial: nil, sedes: nil, list_exception: nil)
        if message.nil?
          raise ArgumentError, "list_exception must be present" if list_exception.nil?

          if list_exception.element_exception
            raise ArgumentError, "sedes must be present" if sedes.nil?

            field = sedes.serializable_fields.keys[list_exception.index]
            message = "Deserialization failed because of field #{field} ('#{list_exception.element_exception}')"
          else
            field = nil
            message = "Deserialization failed because of underlying list ('#{list_exception}')"
          end
        end
        super(message, serial)
        @sedes = sedes
        @field = field
        @list_exception = list_exception
      end
    end
  end
end
