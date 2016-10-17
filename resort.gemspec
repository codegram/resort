# -*- encoding: utf-8 -*-
# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'resort/version'

Gem::Specification.new do |s|
  s.name        = 'resort'
  s.version     = Resort::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Oriol Gual', 'Josep M. Bach', 'Josep Jaume Rey']
  s.email       = ['info@codegram.com']
  s.homepage    = 'http://codegram.github.com/resort'
  s.summary     = 'Positionless model sorting for Rails.'
  s.description = 'Positionless model sorting for Rails.'

  s.required_ruby_version = '>= 2.2.2'

  s.add_dependency 'activerecord', ['>= 4.0.0']
  s.add_dependency 'activesupport', ['>= 4.0.0']
  s.add_dependency 'railties', ['>= 4.0.0']
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'generator_spec'
  s.add_development_dependency 'yard'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
