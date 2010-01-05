$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'yieldmanager'
require 'spec'
require 'spec/autorun'
require 'patch_detector'
Spec::Runner.configure do |config|
  
end
