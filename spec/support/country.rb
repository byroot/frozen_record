class Country < FrozenRecord::Base
  self.default_attributes = { contemporary: true, available: true }

  add_index :name, unique: true
  add_index :continent

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
