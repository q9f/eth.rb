# -*- encoding : ascii-8bit -*-

require 'spec_helper'

module TypeHelper
  extend RSpec::SharedContext

  let(:integer) { 1145256125817859742934257 }
  let(:hex) { "f284757fec556200a4f1" }
  let(:bytes) { "\xF2\x84u\x7F\xECUb\x00\xA4\xF1" }
  let(:prefixed_hex) { "0x#{hex}" }
  let(:zpadded_bytes) { "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xF2\x84u\x7F\xECUb\x00\xA4\xF1" }
  let(:zpadded_hex) { "00000000000000000000000000000000000000000000f284757fec556200a4f1" }

  def expects_correct_values_for(subject)
    expect(subject.integer).to eq(integer)
    expect(subject.hex).to eq(hex)
    expect(subject.bytes).to eq(bytes)
    expect(subject.to_prefixed_hex).to eq(prefixed_hex)
    expect(subject.to_zpadded_bytes).to eq(zpadded_bytes)
    expect(subject.to_zpadded_hex).to eq(zpadded_hex)
  end
end
