# -*- encoding : ascii-8bit -*-

require "spec_helper"

describe Rlp::Sedes do
  describe "inference" do
    subject(:pairs) {
      [
        [5, Rlp::Sedes.big_endian_int],
        [0, Rlp::Sedes.big_endian_int],
        [-1, nil],
        ["", Rlp::Sedes.binary],
        ["asdf", Rlp::Sedes.binary],
        ['\xe4\xf6\xfc\xea\xe2\xfb', Rlp::Sedes.binary],
        [[], Rlp::Sedes::List.new],
        [[1, 2, 3], Rlp::Sedes::List.new(elements: [Rlp::Sedes.big_endian_int] * 3)],
        [[[], "asdf"], Rlp::Sedes::List.new(elements: [[], Rlp::Sedes.binary])],
      ]
    }
    it "can infer all upstream sedes tests" do
      pairs.each do |obj, sedes|
        unless sedes.nil?
          inferred = Rlp::Sedes.infer obj
          expect(inferred).to eq sedes
        else
          expect {Rlp::Sedes.infer obj}.to raise_error TypeError
        end
      end
    end
  end
end
