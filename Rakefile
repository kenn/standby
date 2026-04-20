require 'bundler/gem_helper'
Bundler::GemHelper.install_tasks(name: 'standby')

# RSpec
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec
