# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "resort/version"

Gem::Specification.new do |s|
  s.name        = "resort"
  s.version     = Resort::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Oriol Gual", "Josep M. Bach", "Josep Jaume Rey"]
  s.email       = ["info@codegram.com"]
  s.homepage    = "http://codegram.github.com/resort"
  s.summary     = %q{Positionless model sorting for Rails 3.}
  s.description = %q{Positionless model sorting for Rails 3.}

  s.rubyforge_project = "resort"

  s.add_runtime_dependency 'activerecord', '>= 3.0.5', '< 3.2'
#  s.add_runtime_dependency 'activerecord', '~> 3.0.5'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec', '~> 2.5.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'bluecloth'
  s.add_development_dependency 'generator_spec', '~> 0.8.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
