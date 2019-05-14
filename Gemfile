source 'http://rubygems.org'

gemspec

case version = ENV['MONGOID_VERSION'] || '~> 5.0'
when /7/
  gem 'mongoid', '~> 7.0'
when /6/
  gem 'mongoid', '~> 6.0'
when /5/
  gem 'mongoid', '~> 5.0'
when /4/
  gem 'mongoid', '~> 4.0'
when /3/
  gem 'mongoid', '~> 3.1'
else
  gem 'mongoid', version
end

group :development do
  gem 'bundler', '~> 1.0'
  gem 'dalli', '~> 2.6'
  gem 'rake'
  gem 'rubocop'
  gem 'yard', '~> 0.6'
end

group :test do
  gem 'mongoid-compatibility'
  gem 'rspec', '~> 3.1'
end
