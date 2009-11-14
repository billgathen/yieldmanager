#!/usr/bin/env ruby -w

require 'soap/wsdlDriver'

class Yieldmanager
  attr_accessor :user, :pass, :base_url
  
  def initialize(opts = nil)
    unless opts && opts[:user] && opts[:pass] && opts[:base_url]
      raise ArgumentError, ":user, :pass and :base_url are required"
    end
    @user = opts[:user]
    @pass = opts[:pass]
    @base_url = opts[:base_url]
  end
end