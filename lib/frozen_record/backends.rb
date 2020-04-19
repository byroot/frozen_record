# frozen_string_literal: true

module FrozenRecord
  module Backends
    autoload :Json, 'frozen_record/backends/json'
    autoload :Yaml, 'frozen_record/backends/yaml'
    autoload :Csv, 'frozen_record/backends/csv'
  end
end
