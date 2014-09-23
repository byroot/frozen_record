# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'frozen_record/version'

Gem::Specification.new do |spec|
  spec.name          = 'frozen_record'
  spec.version       = FrozenRecord::VERSION
  spec.authors       = ['Jean Boussier']
  spec.email         = ['jean.boussier@gmail.com']
  spec.summary       = %q{ActiveRecord like interface to read only access and query static YAML files}
  spec.homepage      = 'https://github.com/byroot/frozen_record'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activemodel'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'coveralls'
end
