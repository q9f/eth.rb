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

# Provides the {Eth} module.
module Eth

  # Defines the major version of the {Eth} module.
  MAJOR = 0.freeze

  # Defines the minor version of the {Eth} module.
  MINOR = 5.freeze

  # Defines the patch version of the {Eth} module.
  PATCH = 14.freeze

  # Defines the version string of the {Eth} module.
  VERSION = [MAJOR, MINOR, PATCH].join(".").freeze
end
