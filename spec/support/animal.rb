class Animal < FrozenRecord::Base
  self.backend = FrozenRecord::Backends::Json
end

module Compact
  class Animal < ::Animal
    include FrozenRecord::Compact
    def self.file_path
      superclass.file_path
    end
  end
end
