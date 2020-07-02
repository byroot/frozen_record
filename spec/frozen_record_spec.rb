require 'spec_helper'

RSpec.shared_examples 'main' do

  describe '.primary_key' do

    around do |example|
      previous_primary_key = country_model.primary_key
      begin
        example.run
      ensure
        country_model.primary_key = previous_primary_key
      end
    end

    it 'is coerced to string' do
      country_model.primary_key = :foobar
      expect(country_model.primary_key).to be == 'foobar'
    end

  end

  describe '.auto_reloading' do

    context 'when enabled' do

      around do |example|
        previous_auto_reloading = country_model.auto_reloading
        country_model.auto_reloading = true
        begin
          example.run
        ensure
          country_model.auto_reloading = previous_auto_reloading
        end
      end

      it 'reloads the records if the file mtime changed' do
        mtime = File.mtime(country_model.file_path)
        expect {
          File.utime(mtime + 1, mtime + 1, country_model.file_path)
        }.to change { country_model.first.object_id }
      end

      it 'does not reload if the file has not changed' do
        expect(country_model.first.object_id).to be == country_model.first.object_id
      end

    end

    context 'when disabled' do

      it 'does not reloads the records if the file mtime changed' do
        mtime = File.mtime(country_model.file_path)
        expect {
          File.utime(mtime + 1, mtime + 1, country_model.file_path)
        }.to_not change { country_model.first.object_id }
      end

    end

  end

  describe '.default_attributes' do

    it 'define the attribute' do
      expect(country_model.new).to respond_to :contemporary
    end

    it 'sets the value as default' do
      expect(country_model.find_by(name: 'Austria').contemporary).to be == true
    end

    it 'gives precedence to the data file' do
      expect(country_model.find_by(name: 'Austria').available).to be == false
    end

    it 'is also set in the initializer' do
      expect(country_model.new.contemporary).to be == true
    end

  end

  describe '.scope' do

    it 'defines a scope method' do
      country_model.scope :north_american, -> { where(continent: 'North America') }
      expect(country_model).to respond_to(:north_american)
      expect(country_model.north_american.first.name).to be == 'Canada'
    end

  end

  describe '.memsize' do

    it 'retuns the records memory footprint' do
      # Memory footprint is very dependent on the Ruby implementation and version
      expect(country_model.memsize).to be > 0
      expect(car_model.memsize).to be > 0
    end

  end

  describe '#load_records' do

    it 'processes erb by default' do
      country = country_model.first
      expect(country.capital).to be == 'Ottawa'
    end

    it 'loads records with a custom backend' do
      animal = animal_model.first
      expect(animal.name).to be == 'cat'
    end

  end

  describe '#==' do

    it 'returns true if both instances are from the same class and have the same id' do
      country = country_model.first
      second_country = country.dup

      expect(country).to be == second_country
    end

    it 'returns false if both instances are not from the same class' do
      country = country_model.first
      car = car_model.new(id: country.id)

      expect(country).to_not be == car
    end

    it 'returns false if both instances do not have the same id' do
      country = country_model.first
      second_country = country_model.last

      expect(country).to_not be == second_country
    end

  end

  describe '#attributes' do

    it 'returns a Hash of the record attributes' do
      attributes = country_model.first.attributes
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
        'official_languages' => %w(English French)
      }
    end

  end

  describe '`attribute`?' do

    let(:blank) { country_model.new(id: 0, name: '', nato: false, king: nil) }

    let(:present) { country_model.new(id: 42, name: 'Groland', nato: true, king: Object.new) }

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
      expect(country_model.first).to be_present
    end

  end

  describe '#count' do

    it 'can count objects with no records' do
      expect(car_model.count).to be 0
    end

    it 'can count objects with records' do
      expect(country_model.count).to be 3
    end

  end
end

describe FrozenRecord::Base do
  let(:country_model) { Country }
  let(:car_model) { Car }
  let(:animal_model) { Animal }

  it_behaves_like 'main'

  describe '.base_path' do

    it 'raise a RuntimeError on first query attempt if not set' do
      allow(country_model).to receive_message_chain(:base_path).and_return(nil)
      expect {
        country_model.file_path
      }.to raise_error(ArgumentError)
    end

  end
end

describe FrozenRecord::Compact do
  let(:country_model) { Compact::Country }
  let(:car_model) { Compact::Car }
  let(:animal_model) { Compact::Animal }

  it_behaves_like 'main'
end
