# frozen_string_literal: true

require 'yaml'
require 'set'
require 'active_model'

require 'frozen_record/version'
require 'frozen_record/scope'
require 'frozen_record/index'
require 'frozen_record/base'
require 'frozen_record/compact'

module FrozenRecord
  RecordNotFound = Class.new(StandardError)

  class << self
    attr_accessor :deprecated_yaml_erb_backend

    def eager_load!
      p [:FrozenRecord_eager_load!]
      Base.descendants.each do |model|
        p [model.name, :eager_load!]
        model.eager_load!
      end
    end
  end

  self.deprecated_yaml_erb_backend = false
end
