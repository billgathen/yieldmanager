require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "yieldmanager"
    gem.summary = %Q{Interact with RightMedia's YieldManager API and Reportware products}
    gem.description = %Q{This gem offers full access to YieldManager's API tools (read/write) as well as ad-hoc reporting through the Reportware tool}
    gem.email = "bill@billgathen.com"
    gem.homepage = "http://github.com/billgathen/yieldmanager"
    gem.authors = ["Bill Gathen"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "hpricot", "= 0.8.2"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "yieldmanager #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :yieldmanager do
  desc "Build local wsdl repository for supplied version"
  task :get_wsdls do
    api_version = ENV['API_VERSION']
    unless api_version
      raise ArgumentError, "Please supply API_VERSION"
    end
    require 'lib/yieldmanager/builder'
    Yieldmanager::Builder.build_wsdls_for(api_version)
  end
  
  desc "Delete wsdls for supplied version"
  task :delete_wsdls do
    api_version = ENV['API_VERSION']
    unless api_version
      raise ArgumentError, "Please supply API_VERSION"
    end
    require 'lib/yieldmanager/builder'
    Yieldmanager::Builder.delete_wsdls_for(api_version)
  end
end
