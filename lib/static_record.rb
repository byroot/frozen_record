require 'set'
require 'active_support/all'
require 'active_model'

require 'static_record/version'
require 'static_record/scope'
require 'static_record/base'

module StaticRecord
  RecordNotFound = Class.new(StandardError)
end
