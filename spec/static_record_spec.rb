require 'spec_helper'

describe StaticRecord::Base do

  describe 'querying' do

    describe '.first' do

      it 'returns the first country' do
        country = Country.first
        expect(country.id).to be == 1
      end

      it 'can be called on any scope' do
        country = Country.where(name: 'France').first
        expect(country.id).to be == 2
      end

    end

    describe '.last' do

      it 'returns the first country' do
        country = Country.last
        expect(country.id).to be == 2
      end

      it 'can be called on any scope' do
        country = Country.where(name: 'Canada').last
        expect(country.id).to be == 1
      end

    end

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

    describe '.where' do

      it 'returns the records that match given criterias' do
        countries = Country.where(name: 'France')
        expect(countries.length).to be == 1
        expect(countries.first.name).to be == 'France'
      end

      it 'is chainable' do
        countries = Country.where(name: 'France').where(id: 1)
        expect(countries).to be_empty
      end

    end

    describe '.exists?' do

      it 'returns true if query match at least one record' do
        scope = Country.where(name: 'France')
        expect(scope).to exist
      end

      it 'returns true if query match no records' do
        scope = Country.where(name: 'France', id: 42)
        expect(scope).to_not exist
      end

    end

  end

  describe '#==' do

    it 'returns true if both instances are from the same class and have the same id' do
      country = Country.first
      second_country = country.dup

      expect(country).to be == second_country
    end

    it 'returns false if both instances are not from the same class' do
      country = Country.first
      car = Car.new(id: country.id)

      expect(country).to_not be == car
    end

    it 'returns false if both instances do not have the same id' do
      country = Country.first
      second_country = Country.last

      expect(country).to_not be == second_country
    end

  end

end
