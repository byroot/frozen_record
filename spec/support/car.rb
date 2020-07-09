class Car < FrozenRecord::Base
end

module Compact
  class Car < ::Car
    include FrozenRecord::Compact

    def self.file_path
      superclass.file_path
    end
  end
end
