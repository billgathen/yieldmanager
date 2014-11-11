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
  RSpec.configure do |config|
    # TODO Remove this and convert to expect syntax!
    config.mock_with :rspec do |c|
      c.syntax = [:should, :expect]
    end
    config.expect_with :rspec do |c|
      c.syntax = [:should, :expect]
    end
  end
end
require 'patch_detector'
