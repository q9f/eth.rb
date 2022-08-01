# -*- encoding : ascii-8bit -*-

module TypeHelper
  extend RSpec::SharedContext

  let(:integer) { 1145256125817859742934257 }
  let(:hex) { "f284757fec556200a4f1" }
  let(:bytes) { "\xF2\x84u\x7F\xECUb\x00\xA4\xF1" }
  let(:prefixed_hex) { "0x#{hex}" }
  let(:zpad) { '00000001145256125817859742934257' }

  def expects_correct_values_for(subject)
    expect(subject.dec).to eq(integer)
    expect(subject.hex).to eq(hex)
    expect(subject.to_prefixed_hex).to eq(prefixed_hex)
    expect(subject.bin).to eq(bytes)
    expect(subject.zpad(32)).to eq(zpad)
  end
end
