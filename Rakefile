require 'rubygems'
require 'bundler'

require File.expand_path('../lib/cached-json/version', __FILE__)

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "cached-json"
  gem.homepage = "http://github.com/dblock/cached-json"
  gem.license = "MIT"
  gem.summary = "Effective model-level JSON caching."
  gem.description = "Cached-json is a DSL for describing JSON representations of models."
  gem.email = "dblock@dblock.org"
  gem.version = CachedJSON::VERSION
  gem.authors = [ "Aaron Windsor", "Daniel Doubrovkine" ]
  gem.files = Dir.glob('lib/**/*')
end

Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cached-json #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('LICENSE*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

