class Country < FrozenRecord::Base
  self.base_path = File.join(File.dirname(__FILE__), '..', 'fixtures')

end
