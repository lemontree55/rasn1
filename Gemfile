# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rasn1.gemspec
gemspec

gem 'bundler', '>=1.17', '<3'

group :development do
  # gem 'debase', '~>0.2'
  gem 'ruby-debug-ide', '~> 0.7'
  gem 'simplecov', '~> 0.16'
  gem 'yard', '~>0.9'
end

group :test do
  gem 'rspec', '~> 3.0'
end

group :development, :test do
  gem 'rake', '~> 12.3'
end

group :rubocop do
  gem 'rubocop', '~> 1.0', require: false
  gem 'rubocop-performance', '~> 1.0', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
end
