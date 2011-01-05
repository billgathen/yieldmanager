$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'yieldmanager'
begin
  require 'spec'
  require 'spec/autorun'
  Spec::Runner.configure do |config|
  end
rescue LoadError
  require 'rspec'
  require 'rspec/autorun'
  Rspec.configure do |config|
  end
end
require 'patch_detector'
