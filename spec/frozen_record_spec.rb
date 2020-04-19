require 'spec_helper'

describe FrozenRecord::Base do

  describe '.base_path' do

    it 'raise a RuntimeError on first query attempt if not set' do
      allow(Country).to receive_message_chain(:base_path).and_return(nil)
      expect {
        Country.file_path
      }.to raise_error(ArgumentError)
    end

  end

  describe '.primary_key' do

    around do |example|
      previous_primary_key = Country.primary_key
      begin
        example.run
      ensure
        Country.primary_key = previous_primary_key
      end
    end

    it 'is coerced to string' do
      Country.primary_key = :foobar
      expect(Country.primary_key).to be == 'foobar'
    end

  end

  describe '.auto_reloading' do

    context 'when enabled' do

      around do |example|
        previous_auto_reloading = Country.auto_reloading
        Country.auto_reloading = true
        begin
          example.run
        ensure
          Country.auto_reloading = previous_auto_reloading
        end
      end

      it 'reloads the records if the file mtime changed' do
        mtime = File.mtime(Country.file_path)
        expect {
          File.utime(mtime + 1, mtime + 1, Country.file_path)
        }.to change { Country.first.object_id }
      end

      it 'does not reload if the file has not changed' do
        expect(Country.first.object_id).to be == Country.first.object_id
      end

    end

    context 'when disabled' do

      it 'does not reloads the records if the file mtime changed' do
        mtime = File.mtime(Country.file_path)
        expect {
          File.utime(mtime + 1, mtime + 1, Country.file_path)
        }.to_not change { Country.first.object_id }
      end

    end

  end

  describe '.default_attributes' do

    it 'define the attribute' do
      expect(Country.new).to respond_to :contemporary
    end

    it 'sets the value as default' do
      expect(Country.find_by(name: 'Austria').contemporary).to be == true
    end

    it 'gives precedence to the data file' do
      expect(Country.find_by(name: 'Austria').available).to be == false
    end

    it 'is also set in the initializer' do
      expect(Country.new.contemporary).to be == true
    end

  end

  describe '.scope' do

    it 'defines a scope method' do
      Country.scope :north_american, -> { Country.where(continent: 'North America') }
      expect(Country).to respond_to(:north_american)
      expect(Country.north_american.first.name).to be == 'Canada'
    end

  end

  describe '.memsize' do

    it 'retuns the records memory footprint' do
      # Memory footprint is very dependent on the Ruby implementation and version
      expect(Country.memsize).to be > 0
      expect(Car.memsize).to be > 0
    end

  end

  describe '#load_records' do

    it 'processes erb by default' do
      country = Country.first
      expect(country.capital).to be == 'Ottawa'
    end

    it 'loads records with a custom backend json' do
      animal = Animal.first
      expect(animal.name).to be == 'cat'
    end

    it 'loads records with a custom backend csv' do
      employee = Employee.first
      expect(employee.name).to be == 'john doe'
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

  describe '#attributes' do

    it 'returns a Hash of the record attributes' do
      attributes = Country.first.attributes
      expect(attributes).to be == {
        'id' => 1,
        'name' => 'Canada',
        'capital' => 'Ottawa',
        'density' => 3.5,
        'population' => 33.88,
        'founded_on' => Date.parse('1867-07-01'),
        'updated_at' => Time.parse('2014-02-24T19:08:06-05:00'),
        'king' => 'Elisabeth II',
        'nato' => true,
        'continent' => 'North America',
        'available' => true,
        'contemporary' => true,
      }
    end

  end

  describe '`attribute`?' do

    let(:blank) { Country.new(id: 0, name: '', nato: false, king: nil) }

    let(:present) { Country.new(id: 42, name: 'Groland', nato: true, king: Object.new) }

    it 'considers `0` as missing' do
      expect(blank.id?).to be false
    end

    it 'considers `""` as missing' do
      expect(blank.name?).to be false
    end

    it 'considers `false` as missing' do
      expect(blank.nato?).to be false
    end

    it 'considers `nil` as missing' do
      expect(blank.king?).to be false
    end

    it 'considers other numbers than `0` as present' do
      expect(present.id?).to be true
    end

    it 'considers other strings than `""` as present' do
      expect(present.name?).to be true
    end

    it 'considers `true` as present' do
      expect(present.nato?).to be true
    end

    it 'considers not `nil` objects as present' do
      expect(present.king?).to be true
    end

  end

  describe '#present?' do

    it 'returns true' do
      expect(Country.first).to be_present
    end

  end

  describe '#count' do

    it 'can count objects with no records' do
      expect(Car.count).to be 0
    end

    it 'can count objects with records' do
      expect(Country.count).to be 3
    end

  end
end
