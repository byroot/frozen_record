class Country < FrozenRecord::Base

  def self.republics
    where(king: nil)
  end

  def self.nato
    where(nato: true)
  end

  def reverse_name
    name.reverse
  end
end
