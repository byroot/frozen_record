class Price < FrozenRecord::Base
  add_index :plan_name
  add_index :currency
end

module Compact
  class Price < ::Price
    include FrozenRecord::Compact
    def self.file_path
      superclass.file_path
    end
  end
end
