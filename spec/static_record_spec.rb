require 'spec_helper'

describe StaticRecord::Base do

  describe 'querying' do

    describe '.find' do

      it 'allow to find records by id' do
        country = Country.find(1)
        expect(country.id).to be == 1
        expect(country.name).to be == 'Canada'
      end

      it 'raises a StaticRecord::RecordNotFound error if the id do not exist' do
        expect {
          Country.find(42)
        }.to raise_error(StaticRecord::RecordNotFound)
      end

    end

    describe '.find_by_id' do

      it 'allow to find records by id' do
        country = Country.find_by_id(1)
        expect(country.id).to be == 1
        expect(country.name).to be == 'Canada'
      end

      it 'returns nil if the id do not exist' do
        country = Country.find_by_id(42)
        expect(country).to be_nil
      end

    end

  end

end
