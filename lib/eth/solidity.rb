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

require "open3"

# Provides the {Eth} module.
module Eth

  # Class to create {Solidity} compiler bingings for Ruby.
  class Solidity

    # Provides a Compiler Error in case the contract does not compile.
    class CompilerError < StandardError; end

    # Solidity compiler binary path.
    attr_reader :compiler

    # Instantiates a Solidity `solc` system compiler binding that can be
    # used to compile Solidity contracts.
    def initialize

      # Currently only supports `solc`.
      solc = get_compiler_path
      raise SystemCallError, "Unable to find the solc compiler path!" if solc.nil?
      @compiler = solc
    end

    # Use the bound Solidity executable to compile the given contract.
    #
    # @param contract [String] path of the contract to compile.
    # @return [Array] JSON containing the compiled contract and ABI for all contracts.
    def compile(contract)
      raise Errno::ENOENT, "Contract file not found: #{contract}" unless File.exist? contract
      command = "#{@compiler} --optimize --combined-json bin,abi #{contract}"
      output, error, status = Open3.capture3 command
      raise SystemCallError, "Unable to run solc compiler!" if status.exitstatus === 127
      raise CompilerError, error unless status.success?
      json = JSON.parse output
      result = {}
      json["contracts"].each do |key, value|
        _file, name = key.split ":"
        result[name] = {}
        result[name]["abi"] = value["abi"]
        result[name]["bin"] = value["bin"]
      end
      return result
    end

    private

    # Tries to find a system executable path for the given compiler binary name.
    def get_compiler_path(name = "solc")
      extensions = [""]
      extensions = ENV["PATHEXT"].split(";") unless ENV["PATHEXT"].nil?
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
        extensions.each do |ext|
          executable = File.join path, "#{name}#{ext}"
          return executable if File.executable? executable and !File.directory? executable
        end
      end
      return nil
    end
  end
end
