require "spec_helper"

describe Ens do
  it "has EIP155 chain ids for mainnets, testnets, and devnets" do
    # Chain IDs for selected mainnets
    expect(Ens::DEFAULT_ADDRESS.to_s).to eq "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"
  end
end
