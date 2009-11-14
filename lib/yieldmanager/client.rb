#!/usr/bin/env ruby -w

require 'soap/wsdlDriver'
require 'open-uri'

module Yieldmanager
  class Client
    attr_accessor :user, :pass, :base_url, :services
  
    def initialize(opts = nil)
      unless opts && opts[:user] && opts[:pass] && opts[:base_url]
        raise ArgumentError, ":user, :pass and :base_url are required"
      end
      @user = opts[:user]
      @pass = opts[:pass]
      @base_url = opts[:base_url]
      @base_url << '/' unless @base_url.match(/\/$/)
      @services = lookup_services(@base_url)
    end
  
    def lookup_services base_url
      services = []
      open("#{base_url}xsd_gen.php?wsdl") do |f|
        f.each_line do |line|
          if line.match(/xmlns:api=".*\/(\w+)Service"/)
            services << $1.downcase
          end
        end
      end
      services
    end
  end
end