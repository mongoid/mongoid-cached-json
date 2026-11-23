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
  gem 'yard', '~> 0.6'
end

group :test do
  gem 'mongoid-compatibility'
  gem 'rspec', '~> 3.1'
  gem 'simplecov', '~> 0.22' if ENV['COVERAGE'] == 'true'
end

group :development, :test do
  if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-md', '~> 3.0', require: false
    gem 'rubocop-prose', '~> 0.2', require: false
    gem 'rubocop-rake', '~> 0.7', require: false
    gem 'rubocop-spellcheck', '~> 0.2', require: false
    gem 'rubocop-yaml', '~> 0.1.0', require: false
  end
end
