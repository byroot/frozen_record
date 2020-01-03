class Animal < FrozenRecord::Base
  self.backend = FrozenRecord::Backends::Json
end
