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

  describe '.first!' do

    it 'raises if no record found' do
      expect {
        Country.where(name: 'not existing').first!
      }.to raise_error(FrozenRecord::RecordNotFound)
    end

    it 'doesn\'t raise if record found' do
      expect {
        Country.first!
      }.to_not raise_error
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

  describe '.last!' do

    it 'raises if no record found' do
      expect {
        Country.where(name: 'not existing').last!
      }.to raise_error(FrozenRecord::RecordNotFound)
    end

    it 'doesn\'t raise if record found' do
      expect {
        Country.last!
      }.to_not raise_error
    end

  end

  describe '.find' do

    it 'allow to find records by id' do
      country = Country.find(1)
      expect(country.id).to be == 1
      expect(country.name).to be == 'Canada'
    end

    it 'raises a FrozenRecord::RecordNotFound error if the id do not exist' do
      expect {
        Country.find(42)
      }.to raise_error(FrozenRecord::RecordNotFound)
    end

    it 'raises a FrozenRecord::RecordNotFound error if the id exist but do not match criterias' do
      expect {
        Country.where.not(id: 1).find(1)
      }.to raise_error(FrozenRecord::RecordNotFound)
    end

    it 'is not restricted by :limit and :offset' do
      country = Country.offset(100).limit(1).find(1)
      expect(country).to be == Country.first
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

  describe '.find_by' do

    it 'returns the first matching record' do
      country = Country.find_by(name: 'France', density: 116)
      expect(country.name).to be == 'France'
    end

    it 'returns nil if no records match' do
      country = Country.find_by(name: 'England', density: 116)
      expect(country).to be_nil
    end

  end

  describe '.find_by!' do

    it 'returns the first matching record' do
      country = Country.find_by!(name: 'France', density: 116)
      expect(country.name).to be == 'France'
    end

    it 'returns nil if no records match' do
      expect {
        Country.find_by!(name: 'England', density: 116)
      }.to raise_error(FrozenRecord::RecordNotFound)
    end

  end

  describe 'dynamic_matchers' do

    it 'returns the first matching record' do
      country = Country.find_by_name_and_density('France', 116)
      expect(country.name).to be == 'France'
    end

    it 'returns nil if no records match' do
      country = Country.find_by_name_and_density('England', 116)
      expect(country).to be_nil
    end

    it 'can be used on a scope' do
      country = Country.republics.find_by_name_and_density('France', 116)
      expect(country.name).to be == 'France'

      country = Country.republics.find_by_name('Canada')
      expect(country).to be_nil
    end

    it 'hook into respond_to?' do
      expect(Country).to respond_to :find_by_name_and_density
      expect(Country.republics).to respond_to :find_by_name_and_density
    end

    it 'do not respond to unknown attributes' do
      expect(Country).to_not respond_to :find_by_name_and_unknown_attribute
      expect(Country.republics).to_not respond_to :find_by_name_and_unknown_attribute
    end

  end

  describe 'dynamic_matchers!' do

    it 'returns the first matching record' do
      country = Country.find_by_name_and_density!('France', 116)
      expect(country.name).to be == 'France'
    end

    it 'returns nil if no records match' do
      expect {
        Country.find_by_name_and_density!('England', 116)
      }.to raise_error(FrozenRecord::RecordNotFound)
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
      expect(countries.length).to be == 0
    end

    it 'can be used with arrays' do
      countries = Country.where(id: [1,2])
      expect(countries.length).to be == 2
    end

    it 'can be used with ranges' do
      countries = Country.where(id: (1..2))
      expect(countries.length).to be == 2
    end

  end

  describe '.where.not' do

    it 'returns the records that do not mach given criterias' do
      countries = Country.where.not(name: 'France')
      expect(countries.length).to be == 2
      expect(countries.map(&:name)).to be == %w(Canada Austria)
    end

    it 'is chainable' do
      countries = Country.where.not(name: 'France').where(id: 1)
      expect(countries.length).to be == 1
      expect(countries.map(&:name)).to be == %w(Canada)
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

      it 'reorder records by given attribute and specified order' do
        countries = Country.order(name: :desc).pluck(:name)
        expect(countries).to be == %w(France Canada Austria)
      end

    end

    context 'when passed arguments that are not attributes' do

      it 'reorder records by calling the given method name' do
        countries = Country.order(:reverse_name).pluck(:reverse_name)
        expect(countries).to be == %w(adanaC airtsuA ecnarF)
      end

    end
  end

  describe '.limit' do

    it 'retuns only the amount of required records' do
      countries = Country.limit(1)
      expect(countries.length).to be == 1
      expect(countries.to_a).to be == [Country.first]
    end

  end

  describe '.offset' do

    it 'skip the amount of required records' do
      countries = Country.offset(1)
      expect(countries.length).to be == 2
      expect(countries.to_a).to be == [Country.find(2), Country.find(3)]
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

  describe '.ids' do

    context 'when called with no arguments' do

      it 'returns an array of ids' do
        ids = Country.ids
        expect(ids).to be == [1, 2, 3]
      end

    end

    context 'when called on a scope' do

      it 'returns only the ids of matching records' do
        ids = Country.where(capital: "Ottawa").ids
        expect(ids).to be == [1]
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

  describe '.sum' do

    it 'returns the sum of the column argument' do
      sum = Country.sum(:population)
      expect(sum).to be_within(0.00000000000002).of(108.042)
    end

  end

  describe '.average' do

    it 'returns the average of the column argument' do
      average = Country.average(:density)
      expect(average).to be == 73.26666666666667
    end

  end

  describe '.minimum' do

    it 'returns the average of the column argument' do
      minimum = Country.minimum(:density)
      expect(minimum).to be == 3.5
    end

  end

  describe '.maximum' do

    it 'returns the average of the column argument' do
      maximum = Country.maximum(:density)
      expect(maximum).to be == 116
    end

  end

  describe '.to_json' do

    it 'serialize the results' do
      json = Country.all.to_json
      expect(json).to be == Country.all.to_a.to_json
    end

  end

  describe '.as_json' do

    it 'serialize the results' do
      json = Country.all.as_json
      expect(json).to be == Country.all.to_a.as_json
    end

  end

  describe '.to_xml' do

    it 'serialize the results' do
      skip('ActiveModel::Serializers::Xml is not defined (Active Model 5+ ?)') unless defined? ActiveModel::Serializers::Xml
      xml = Country.all.to_xml
      expect(xml).to be == Country.all.to_a.to_xml
    end

  end

  describe '#==' do
    it 'returns true when two scopes share the same hashed attributes' do
      scope_a = Country.republics.nato
      scope_b = Country.republics.nato
      expect(scope_a.object_id).not_to be == scope_b.object_id
      expect(scope_a).to be == scope_b
    end

    it 'returns true when the same scope has be rechained' do
      scope_a = Country.nato.republics.nato.republics
      scope_b = Country.republics.nato
      expect(scope_a.instance_variable_get(:@where_values)).to be == [[:nato, true ], [:king, nil ], [:nato, true], [:king, nil]]
      expect(scope_b.instance_variable_get(:@where_values)).to be == [[:king, nil ], [:nato, true]]
      expect(scope_a).to be == scope_b
    end
  end

  describe 'class methods delegation' do

    it 'can be called from a scope' do
      ids = Country.where(name: 'France').republics.pluck(:id)
      expect(ids).to be == [2]
    end

  end

end
