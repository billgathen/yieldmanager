dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)
# The module that contains everything Yieldmanager-related:
#
# * {Yieldmanager::Client} is the class used to interact with Yieldmanager.
# * {Yieldmanager::Builder} creates local copies of the YM service wsdls.
#
require 'yieldmanager/client'
require 'yieldmanager/builder'
