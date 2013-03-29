require 'bundler'
Bundler::GemHelper.install_tasks

if RUBY_VERSION >= "1.9.0"
  require "rspec/core/rake_task" # RSpec 2.0

  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/yieldmanager/*_spec.rb'
  end
else
  require "spec/rake/spectask"  # RSpec 1.3

  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.spec_files = FileList['spec/yieldmanager/*_spec.rb']
  end
end

task :default => :spec
