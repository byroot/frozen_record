class CurrencyCode
  class << self
    def load(value)
      value.to_sym
    end
  end
end

class TectonicString < String
  class << self
    alias_method :load, :new
  end
end

class Country < FrozenRecord::Base
  self.default_attributes = { contemporary: true, available: true, currency_code: CurrencyCode.load('EUR') }

  add_index :name, unique: true
  add_index :continent

  attribute :currency_code, CurrencyCode
  attribute :continent, TectonicString

  def self.republics
    where(king: nil)
  end

  def self.nato
    where(nato: true)
  end

  def self.continent_and_capital(continent, capital:)
    where(continent: continent, capital: capital)
  end

  def reverse_name
    name.reverse
  end
end

module Compact
  class Country < ::Country
    include FrozenRecord::Compact
    def self.file_path
      superclass.file_path
    end
  end
end
