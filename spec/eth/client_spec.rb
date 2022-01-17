require "spec_helper"

describe Client do
describe ".create .initialize" do
  it "creates an http client" do
    expect(Client.create "/tmp/geth.ipc").to be_instance_of Eth::Client::Ipc
  end

  it "creates an ipc client" do
    expect(Client.create "http://127.0.0.1:8485").to be_instance_of Eth::Client::Http
  end
end
end