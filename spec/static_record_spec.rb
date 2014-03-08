require 'spec_helper'

describe StaticRecord::Base do

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

  describe '`attribute`?' do

    let(:blank) { Country.new(id: 0, name: '', nato: false, king: nil) }

    let(:present) { Country.new(id: 42, name: 'Groland', nato: true, king: Object.new) }

    it 'considers `0` as missing' do
      expect(blank.id?).to be_false
    end

    it 'considers `""` as missing' do
      expect(blank.name?).to be_false
    end

    it 'considers `false` as missing' do
      expect(blank.nato?).to be_false
    end

    it 'considers `nil` as missing' do
      expect(blank.king?).to be_false
    end

    it 'considers other numbers than `0` as present' do
      expect(present.id?).to be_true
    end

    it 'considers other strings than `""` as present' do
      expect(present.name?).to be_true
    end

    it 'considers `true` as present' do
      expect(present.nato?).to be_true
    end

    it 'considers not `nil` objects as present' do
      expect(present.king?).to be_true
    end

  end

end
