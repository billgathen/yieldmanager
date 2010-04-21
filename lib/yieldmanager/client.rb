require 'rubygems'
require 'soap/wsdlDriver'
require 'open-uri'
require 'hpricot'

# Monkey-patch to eliminate bogus "cannot be null" errors from YM wsdl
class WSDL::XMLSchema::SimpleType
  private
  def check_restriction(value)
    unless @restriction.valid?(value) || @name.to_s =~ /(enum_creative_third_party_types|enum_ym_numbers_difference)/
      raise XSD::ValueSpaceError.new("#{@name}: cannot accept '#{value}'")
    end
  end
end

module Yieldmanager
  # This is the frontend for using Yieldmanager programmatically.
  # It can be directly used by the user by creating a
  # new instance and calling +service_name+ to access YM services.
  # For example:
  #
  #   ym = Yieldmanager::Client(
  #     :user => "bob",
  #     :pass => "secret",
  #     :api_version => "1.31"
  #   )
  #
  #   ym.session do |token|
  #     currencies = @ym.dictionary.getCurrencies(token)
  #   end
  #
  # It also offers simple access to the ReportWare reporting engine
  # via the #pull_report method.
  class Client
    # Yieldmanager user
    attr_reader :user
    # Yieldmanager password
    attr_reader :pass
    # Yieldmanager api version (i.e., "1.31")
    attr_reader :api_version
    # Yieldmanager environment ("prod" or "test", defaults to "prod")
    attr_reader :env
    BASE_URL = "https://api.yieldmanager.com/api-"
    BASE_URL_TEST = "https://api-test.yieldmanager.com/api-"
    WSDL_DIR = File.join(File.dirname(__FILE__), '..', '..', 'wsdls')
  
    # Creates interface object.
    #
    # Options:
    # * :user (required) - Yieldmanager user
    # * :pass (required) - Yieldmanager pass
    # * :api_version (required) - Yieldmanager API version (i.e., "1.31")
    # * :env (optional) - Yieldmanager environment "prod" or "test" (defaults to prod)
    def initialize(options = nil)
      unless options &&
        (options[:user] || options['user']) &&
        (options[:pass] || options['pass']) &&
        (options[:api_version] || options['api_version'])
        raise ArgumentError, ":user, :pass and :api_version are required"
      end
      @user = options[:user] ||= options['user']
      @pass = options[:pass] ||= options['pass']
      @api_version = options[:api_version] ||= options['api_version']
      if options[:env]
        @env = options[:env]
      elsif options['env']
        @env = options['env']
      else
        @env = "prod"
      end
      @wsdl_dir = "#{WSDL_DIR}/#{@api_version}/#{@env}"
      wrap_services
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
    
    # Manages Yieldmanager session
    #
    # Returns block with token string to be used in API/report calls
    #
    # Guarantees no hanging sessions except during system crashes
    def session
      token = start_session
      begin
        yield token
      ensure
        end_session token
      end
    end
    
    # Opens Yieldmanager session
    #
    # Use #session if possible: it guarantees no hanging sessions
    def start_session
      contact.login(@user,@pass,{'errors_level' => 'throw_errors','multiple_sessions' => '1'})
    end
    
    # Closes Yieldmanager session
    #
    # Use #session if possible: it guarantees no hanging sessions
    def end_session token
      contact.logout(token)
    end
    
    # Allows looping over datasets too large to pull back in one call
    #
    # Block must return total rows in dataset to know when to stop!
    def paginate block_size
      page = 1
      total = block_size + 1

      begin
        total = yield page # Need total back from block to know when to stop!
        page += 1
      end until (block_size * (page-1)) > total
    end
    
    # Pulls report from RightMedia, returned as Yieldmanager::Report
    #
    # Must be called within the context of a session
    def pull_report token, xml
      report = Yieldmanager::Report.new
      report.pull(token, self.report, xml)
      report
    end

private
    
    def wrap_services
      available_services.each do |s|
        self.class.send(:attr_writer, s.to_sym)
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
      base_url = (@env == "prod" ? BASE_URL : BASE_URL_TEST)
      wsdl_path = "#{base_url}#{api_version}/#{name}.php?wsdl"
      SOAP::WSDLDriverFactory.new(wsdl_path).create_rpc_driver
    end
  end
end