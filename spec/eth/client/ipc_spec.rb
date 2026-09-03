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

require "spec_helper"
require "socket"

describe Client::Ipc do
  subject(:client) { described_class.new("/tmp/geth.ipc") }

  describe "#send_request" do
    it "closes the socket even if the request fails" do
      socket = instance_double(UNIXSocket, closed?: false)
      allow(UNIXSocket).to receive(:new).and_return(socket)
      allow(socket).to receive(:puts)
      allow(socket).to receive(:recvmsg).and_raise(IOError)
      expect(socket).to receive(:close)
      expect { client.send(:send_request, "{}") }.to raise_error(IOError)
    end
  end

  describe "#close" do
    it "is safe to call multiple times" do
      expect { client.close }.not_to raise_error
      expect { client.close }.not_to raise_error
    end

    it "marks the client as closed" do
      expect(client.closed?).to be_falsey
      client.close
      expect(client.closed?).to be_truthy
    end

    it "raises an IOError on subsequent requests" do
      client.close
      expect { client.eth_chain_id }.to raise_error(IOError, "The client is closed!")
    end
  end
end
