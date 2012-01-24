dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)
# The module that contains everything Yieldmanager-related:
#
# * Yieldmanager::Client is the class used to interact with Yieldmanager.
# * Yieldmanager::Report is the data object returned by ReportWare calls.
#
module Yieldmanager
end

require 'patch_detector'
include PatchDetector

if (RUBY_VERSION.start_with?("1.9"))
  #
  # This patch based on Tomer Doron's "Fixing soap4r for ruby 1.9" post
  # http://tomerdoron.blogspot.com/2009/10/fixing-soap4r-for-ruby-19.html
  #
  $LOAD_PATH.unshift "#{dir}/soap4r_19_patch"
end

require 'yieldmanager/client'

if needs_patching?(:ruby_version => RUBY_VERSION, :minimum_ruby_version_for_patch => "1.8.7")
  require 'wsdl/patch'
end

require 'yieldmanager/report'
