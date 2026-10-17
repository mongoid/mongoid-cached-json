source 'https://rubygems.org'

gemspec

version = ENV['MONGOID_VERSION'] || '9'
gem 'bigdecimal' if RUBY_VERSION >= '3.4'
gem 'logger' if RUBY_VERSION >= '3.4'
gem 'mongoid', version =~ /\A\d+\z/ ? "~> #{version}.0" : version

group :development do
  if RUBY_VERSION >= '2.7'
    gem 'danger'
    gem 'danger-changelog', require: false
    gem 'danger-pr-comment', require: false
  end
  gem 'dalli', RUBY_VERSION >= '3.0' ? '~> 3.0' : '~> 2.6'
  gem 'rake'
  gem 'rdoc', RUBY_VERSION >= '3.0' ? '>= 6' : '~> 4.2'
  gem 'rubocop', ENV.fetch('RUBOCOP_VERSION', '>= 0')
  gem 'yard', '~> 0.6'
end

group :test do
  gem 'mongoid-compatibility'
  gem 'rspec', '~> 3.1'
  gem 'simplecov', '~> 0.22' if ENV['COVERAGE'] == 'true'
end
