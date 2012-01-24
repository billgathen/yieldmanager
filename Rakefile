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
    gem.add_development_dependency "rdoc"
    gem.add_dependency "hpricot", "= 0.8.2"
    gem.add_dependency "soap4r", "= 1.5.8"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

#
# Handle 1.8 + rspec-1 OR 1.9 + rspec-2
# based on http://relishapp.com/rspec/rspec-core/v/2-6/file/upgrade -> "Upgrading from rspec-1.x"
#
if (RUBY_VERSION.start_with?("1.9"))
  # rspec-2
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
    t.pattern = 'spec/**/*_spec.rb'
  end
  
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov_opts =  %q[--exclude "spec"]
  end
else # 1.8
  #rspec-1
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
end

task :spec => :check_dependencies

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "yieldmanager #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :yieldmanager do
  desc "Build wsdls for API version in API_VERSION file"
  task :build_wsdls do
    require './lib/yieldmanager/builder'
    Yieldmanager::Builder.build_wsdls_for(api_version)
  end
  
  desc "Delete wsdls for API version in API_VERSION file"
  task :delete_wsdls do
    require './lib/yieldmanager/builder'
    Yieldmanager::Builder.delete_wsdls_for(api_version)
  end
end

def api_version
  version_file = "API_VERSION"
  path = File.join(File.dirname(__FILE__), version_file)
  unless File.exists?(path)
    fail "Put the API version in a file called #{version_file}"
  end
  File.open(path){ |f| f.readline.chomp }
end
