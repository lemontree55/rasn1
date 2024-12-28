# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rasn1.gemspec
gemspec

gem 'bundler', '>=1.17', '<3'

group :development do
  gem 'debug'
  gem 'ruby-lsp', require: false
  gem 'ruby-lsp-rspec', require: false
  gem 'yard', '~>0.9', require: false
end

group :test do
  gem 'rspec', '~> 3.0', require: false
  gem 'simplecov', '~> 0.22', require: false
end

group :development, :test do
  gem 'rake', '~> 12.3', require: false
end

group :rubocop do
  gem 'rubocop', '~> 1.0', require: false
  gem 'rubocop-performance', '~> 1.0', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
end
