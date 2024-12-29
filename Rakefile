# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task default: :spec

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', '-', 'README.md', 'LICENSE']
    t.options = %w[--no-private]
  end
rescue LoadError # rubocop:disable Lint/SuppressedException
end

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new do |task|
    task.patterns = ['lib/**/*.rb']
  end
rescue LoadError # rubocop:disable Lint/SuppressedException
end
