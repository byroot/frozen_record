# frozen_string_literal: true

require 'yaml'
require 'set'
require 'active_support/all'
require 'active_model'

require 'frozen_record/version'
require 'frozen_record/scope'
require 'frozen_record/base'
require 'frozen_record/deduplication'

module FrozenRecord
  RecordNotFound = Class.new(StandardError)

  class << self
    attr_accessor :deprecated_yaml_erb_backend

    def eager_load!
      Base.descendants.each(&:eager_load!)
    end
  end

  self.deprecated_yaml_erb_backend = true
end

require 'frozen_record/railtie' if defined?(Rails)
