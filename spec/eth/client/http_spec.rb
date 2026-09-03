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

describe Client::Http do
  subject(:client) { described_class.new("http://127.0.0.1:8545") }

  describe "#close" do
    it "closes the underlying HTTP session" do
      session = client.instance_variable_get(:@client)
      expect(session).to receive(:close).and_call_original
      client.close
    end

    it "closes idempotently" do
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
