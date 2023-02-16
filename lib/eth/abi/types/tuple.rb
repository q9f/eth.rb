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

# Provides the {Eth} module.
module Eth

  # Provides a Ruby implementation of the Ethereum Application Binary Interface (ABI).
  module Abi

    # Provides a class to handle and parse tuple types.
    class TupleType < MetaType
      attr_reader :types

      def initialize(types)
        types.each do |type|
          raise ArgumentError, "Invalid sub-type provided: #{type}" unless type.kind_of? MetaType
        end
        @types = types
      end

      def size
        s = 0
        @types.each do |type|
          return nil if type.dynamic?
          s += type.size
        end
        return s
      end

      def format
        "(#{@types.map { |type| type.format }.join(",")})"
      end

      def ==(another_type)
        another_type.kind_of? TupleType and @types == another_type.types
      end
    end
  end
end
