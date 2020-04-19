class Employee < FrozenRecord::Base
  self.backend = FrozenRecord::Backends::Csv
end
