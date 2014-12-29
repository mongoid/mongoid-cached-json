require 'rubygems'
require 'bundler'

require File.expand_path('../lib/mongoid-cached-json/version', __FILE__)

Bundler.setup(:default, :development)
Bundler::GemHelper.install_tasks

require 'rake'

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
