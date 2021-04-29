lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

minimal = ENV['MINIMAL'] == 'true'
require 'objspace'
require 'time'

if minimal
  require 'frozen_record/minimal'
else
  require 'frozen_record'
end

require 'frozen_record/test_helper'

FrozenRecord::Base.base_path = File.join(File.dirname(__FILE__), 'fixtures')

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

FrozenRecord.eager_load!

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding :exclude_minimal if minimal

  config.order = 'random'

  config.before { FrozenRecord::TestHelper.unload_fixtures }
end
