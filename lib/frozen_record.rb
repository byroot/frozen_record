require 'set'
require 'active_support/all'
require 'active_model'

require 'frozen_record/version'
require 'frozen_record/scope'
require 'frozen_record/base'

module FrozenRecord
  RecordNotFound = Class.new(StandardError)
end
