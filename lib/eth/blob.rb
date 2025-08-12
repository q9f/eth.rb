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

require "eth/unit"

# Provides the {Eth} module.
module Eth
  # Provides blob related configuration such as scheduled limits and fees.
  module Blob
    # Simple configuration object carrying blob limits and fees.
    Config = Struct.new(:max_blobs, :min_fee_per_blob_gas, keyword_init: true)

    # Default configuration schedule. Additional entries can be appended
    # with future timestamps to adjust limits and fees at a given time.
    @schedule = [
      { time: Time.at(0), config: Config.new(max_blobs: 6, min_fee_per_blob_gas: Unit::WEI) }
    ]

    class << self
      attr_accessor :schedule

      # Returns configuration valid for a given point in time.
      #
      # @param at [Time] timestamp to evaluate the schedule.
      # @return [Config] configuration matching the provided time.
      def config(at: Time.now)
        entry = @schedule.select { |s| at >= s[:time] }.max_by { |s| s[:time] }
        entry[:config]
      end
    end
  end
end
