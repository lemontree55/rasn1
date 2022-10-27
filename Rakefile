# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task default: :spec

# rubocop:disable Lint/SuppressedException
begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', '-', 'README.md', 'LICENSE']
    t.options = %w[--no-private]
  end
rescue LoadError
end
# rubocop:enable Lint/SuppressedException
