#!/usr/bin/env ruby -w

require 'soap/wsdlDriver'
require 'open-uri'

module Yieldmanager
  class Client
    attr_accessor :user, :pass, :api_version, :env, :services
    BASE_URL = "https://api.yieldmanager.com/api-"
    BASE_URL_TEST = "https://api-test.yieldmanager.com/api-"
    WSDL_DIR = File.join(File.dirname(__FILE__), '..', '..', 'wsdls')
  
    def initialize(opts = nil)
      unless opts && opts[:user] && opts[:pass] && opts[:api_version]
        raise ArgumentError, ":user, :pass and :api_version are required"
      end
      @user = opts[:user]
      @pass = opts[:pass]
      @api_version = opts[:api_version]
      @env = opts[:env] ||= "prod"
      @wsdl_dir = "#{WSDL_DIR}/#{@api_version}/#{@env}"
    end
  
    def available_services
      Dir.entries(@wsdl_dir).map do |wsdl|
        wsdl.sub(/\.wsdl/,'')
      end
    end
  end
end