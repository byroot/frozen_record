require 'spec_helper'

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

    it 'returns the last country' do
      country = Country.last
      expect(country.id).to be == 3
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

  describe '.order' do

    context 'when pased one argument' do

      it 'reorder records by given attribute in ascending order' do
        countries = Country.order(:name).pluck(:name)
        expect(countries).to be == %w(Austria Canada France)
      end

    end

    context 'when passed multiple arguments' do

      it 'reorder records by given attributes in ascending order' do
        countries = Country.order(:updated_at, :name).pluck(:name)
        expect(countries).to be == %w(Austria France Canada)
      end

    end

    context 'when passed a hash' do

      it 'records records by given attribute and specified order' do
        countries = Country.order(name: :desc).pluck(:name)
        expect(countries).to be == %w(France Canada Austria)
      end

    end

  end

  describe '.pluck' do

    context 'when called with a single argument' do

      it 'returns an array of values' do
        names = Country.pluck(:name)
        expect(names).to be == %w(Canada France Austria)
      end

    end

    context 'when called with multiple arguments' do

      it 'returns an array of arrays' do
        names = Country.pluck(:id, :name)
        expect(names).to be == [[1, 'Canada'], [2, 'France'], [3, 'Austria']]
      end

    end

    context 'when called with multiple arguments' do

      it 'returns an array of arrays' do
        names = Country.pluck(:id, :name)
        expect(names).to be == [[1, 'Canada'], [2, 'France'], [3, 'Austria']]
      end

    end

    context 'when called without arguments' do

      pending 'returns an array of arrays containing all attributes in order'

    end

    context 'when called on a scope' do

      it 'returns only the attributes of matching records' do
        names = Country.where(id: 1).pluck(:name)
        expect(names).to be == %w(Canada)
      end

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
