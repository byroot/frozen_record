class Country < FrozenRecord::Base

  def self.republics
    where(king: nil)
  end

end
