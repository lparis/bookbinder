require_relative '../../../../lib/bookbinder/validation_checkers/dita_section_checker'

module Bookbinder
  describe DitaSectionChecker do
    context 'when there is ditamap_location' do
      it 'should return nil' do
        config = {
            'dita_sections' =>
                [
                    {'repository' => {
                        'name' => 'fantastic/dogs-repo'},
                     'ditamap_location' => 'my-special-location'
                    }
                ]

        }
        expect(DitaSectionChecker.new.check(config)).to be_nil
      end
    end

    context 'when there is no ditamap_location' do
      it 'should return the correct error' do
        config = {
            'dita_sections' =>
                [
                    {'repository' => {
                        'name' => 'fantastic/dogs-repo'}
                    }
                ]

        }
        expect(DitaSectionChecker.new.check(config).class).
            to eq DitaSectionChecker::DitamapLocationError
      end
    end

    context 'when there are no dita_sections' do
      it 'returns nil' do
        config = {}
        expect(DitaSectionChecker.new.check(config)).to be_nil
      end
    end
  end
end