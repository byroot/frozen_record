module FrozenRecord
  module Backends
    autoload :Json, 'frozen_record/backends/json'
    autoload :Yaml, 'frozen_record/backends/yaml'
  end
end
