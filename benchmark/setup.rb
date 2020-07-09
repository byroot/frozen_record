require 'bundler/setup'
require 'benchmark/ips'

require 'frozen_record'
require_relative '../spec/support/country'
FrozenRecord::Base.base_path = File.expand_path('../spec/fixtures', __dir__)
