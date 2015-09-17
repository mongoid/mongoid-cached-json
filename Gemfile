source 'http://rubygems.org'

gemspec

case version = ENV['MONGOID_VERSION'] || '~> 5.0'
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
  gem 'rake'
  gem 'bundler', '~> 1.0'
  gem 'yard', '~> 0.6'
  gem 'dalli', '~> 2.6'
  gem 'rubocop', '0.33.0'
end

group :test do
  gem 'mongoid-compatibility'
  gem 'rspec', '~> 3.1'
end
