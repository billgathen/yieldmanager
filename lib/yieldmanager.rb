dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)
# The module that contains everything Yieldmanager-related:
#
# * Yieldmanager::Client is the class used to interact with Yieldmanager.
# * Yieldmanager::Report is the data object returned by ReportWare calls.
# * Yieldmanager::Builder creates local copies of the YM service wsdls.
#
module Yieldmanager
end

require 'patch_detector'
include PatchDetector

require 'yieldmanager/client'

if needs_patching?(:ruby_version => RUBY_VERSION, :minimum_ruby_version_for_patch => "1.8.7")
  require 'wsdl/patch'
end

require 'yieldmanager/builder'
require 'yieldmanager/report'
