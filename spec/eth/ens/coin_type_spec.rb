require "spec_helper"

describe Ens::CoinType do
  it "knows some coin slip-44 types" do
    expect(Ens::CoinType::BITCOIN).to eq 0
    expect(Ens::CoinType::LITECOIN).to eq 2
    expect(Ens::CoinType::DOGECOIN).to eq 3
    expect(Ens::CoinType::ETHEREUM).to eq 60
    expect(Ens::CoinType::ETHEREUM_CLASSIC).to eq 61
    expect(Ens::CoinType::ROOTSTOCK).to eq 137
    expect(Ens::CoinType::BITCOIN_CASH).to eq 145
    expect(Ens::CoinType::BINANCE).to eq 714
  end
end
