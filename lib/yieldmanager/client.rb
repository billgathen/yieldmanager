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
      wrap_services
    end
    
    def wrap_services
      available_services.each do |s|
        self.instance_variable_set("@#{s}", nil)
        # create wrapper method to load it when requested
        self.class.send(:define_method, s) {
          unless self.instance_variable_get("@#{s}")
            self.instance_variable_set("@#{s}",load_service(s))
          end
          self.instance_variable_get("@#{s}")
        }
      end
    end
    
    def load_service name
      # FIXME Local wsdl hit throws "unknown element: {http://schemas.xmlsoap.org/wsdl/}definitions"
      # wsdl_path = "file://#{@wsdl_dir}/#{name}.wsdl"
      wsdl_path = "#{BASE_URL}#{api_version}/#{name}.php?wsdl"
      SOAP::WSDLDriverFactory.new(wsdl_path).create_rpc_driver
    end
  
    def available_services
      Dir.entries(@wsdl_dir).map do |wsdl|
        if wsdl.match(/wsdl/) 
          wsdl.sub(/\.wsdl/,'')
        else
          nil
        end
      end.compact
    end
  end
end