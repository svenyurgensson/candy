require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candy::Piece do
  describe '#to_h' do
    let(:hash) do
      {
        aa: 22,
        b: { bb: { cc: 33 } },
        d: [
          { aa: 1, bb: 2, cc: 3 },
          { aa: [
              { bb: 2, cc: 3 },
              { dd: 4, ee: 5 }
            ] }
        ]
      }
    end
    let(:zag) { Zagnut.new(hash) }

    it 'returns proper hash' do
      #binding.pry
      zag.to_h.should eq(hash)
    end
  end
end
