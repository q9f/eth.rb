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

require "socket"

# Provides the {Eth} module.
module Eth

  # Provides an IPC-RPC client.
  class Client::Ipc < Client

    # The path of the IPC socket.
    attr_accessor :path

    # Constructor for the IPC Client. Should not be used; use
    # {Client.create} intead.
    #
    # @param path [String] an URI pointing to an IPC RPC-API.
    def initialize(path)
      super
      @path = path
    end

    # Sends an RPC request to the connected IPC socket.
    #
    # @param payload [Hash] the RPC request parameters.
    # @return [String] a JSON-encoded response.
    def send(payload)
      socket = UNIXSocket.new(@path)
      socket.puts(payload)
      read = socket.recvmsg(nil)[0]
      until read.end_with?("\n")
        read = read << socket.recvmsg(nil)[0]
      end
      socket.close
      return read
    end
  end
end
