$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'mongoid-cached-json/version'

Gem::Specification.new do |s|
  s.name = 'mongoid-cached-json'
  s.version = Mongoid::CachedJson::VERSION
  s.authors = ['Aaron Windsor', 'Daniel Doubrovkine', 'Frank Macreery']
  s.email = 'dblock@dblock.org'
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = '>= 1.3.6'
  s.files = `git ls-files`.split("\n")
  s.require_paths = ['lib']
  s.homepage = 'http://github.com/mongoid/mongoid-cached-json'
  s.licenses = ['MIT']
  s.summary = 'Cached-json is a DSL for describing JSON representations of Mongoid models.'
  s.add_dependency 'mongoid', '>= 3.0'
end
