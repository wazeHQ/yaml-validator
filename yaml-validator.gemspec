# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yaml-validator/version'

Gem::Specification.new do |gem|
  gem.name          = "yaml-validator"
  gem.version       = YamlValidator::VERSION
  gem.authors       = ["David Elentok"]
  gem.email         = ["3david@gmail.com"]
  gem.description   = %q{YAML locales validator}
  gem.summary       = %q{Validates .yml locale files for Ruby on Rails projects}
  gem.homepage      = "http://github.com/wazeHQ/yaml-validator"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency('rake')
  gem.add_dependency('rspec')
  gem.add_dependency('colorize')
  gem.add_dependency('sanitize')
end
