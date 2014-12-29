require 'rubygems'
require 'bundler'

require File.expand_path('../lib/mongoid-cached-json/version', __FILE__)

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = 'mongoid-cached-json'
  gem.homepage = 'http://github.com/dblock/mongoid-cached-json'
  gem.license = 'MIT'
  gem.summary = 'Effective model-level JSON caching for the Mongoid ODM.'
  gem.description = 'Cached-json is a DSL for describing JSON representations of Mongoid models.'
  gem.email = 'dblock@dblock.org'
  gem.version = Mongoid::CachedJson::VERSION
  gem.authors = ['Aaron Windsor', 'Daniel Doubrovkine', 'Frank Macreery']
  gem.files = Dir.glob('lib/**/*')
end

Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  files = FileList['spec/**/*_spec.rb']
  files = files.exclude 'spec/benchmark_spec.rb'
  spec.pattern = files
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongoid-cached-json #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('LICENSE*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: [:rubocop, :spec]
