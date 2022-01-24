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

  # Provides an recursive-length prefix (RLP) encoder and decoder.
  module Rlp
    module Sedes

      # A sedes for lists of fixed length
      class List < Array
        def initialize(elements: [], strict: true)
          super()
          @strict = strict
          elements.each do |e|
            if Sedes.is_sedes?(e)
              push e
            elsif Util.is_list?(e)
              push List.new(elements: e)
            else
              raise TypeError, "Instances of List must only contain sedes objects or nested sequences thereof."
            end
          end
        end

        def serialize(obj)
          raise Error::ListSerializationError.new(message: "Can only serialize sequences", obj: obj) unless Util.is_list?(obj)
          raise Error::ListSerializationError.new(message: "List has wrong length", obj: obj) if (@strict && self.size != obj.size) || self.size < obj.size
          result = []
          obj.zip(self).each_with_index do |(element, sedes), i|
            begin
              result.push sedes.serialize(element)
            rescue Error::SerializationError => e
              raise Error::ListSerializationError.new(obj: obj, element_exception: e, index: i)
            end
          end
          result
        end

        def deserialize(serial)
          raise Error::ListDeserializationError.new(message: "Can only deserialize sequences", serial: serial) unless Util.is_list?(serial)
          raise Error::ListDeserializationError.new(message: "List has wrong length", serial: serial) if @strict && serial.size != self.size
          result = []
          len = [serial.size, self.size].min
          len.times do |i|
            begin
              sedes = self[i]
              element = serial[i]
              result.push sedes.deserialize(element)
            rescue Error::DeserializationError => e
              raise Error::ListDeserializationError.new(serial: serial, element_exception: e, index: i)
            end
          end
          result.freeze
        end
      end
    end
  end
end
