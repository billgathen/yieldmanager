require 'soap/wsdlDriver'
require 'open-uri'

module Yieldmanager
  # This is the frontend for using Yieldmanager programmatically.
  # It can be directly used by the user by creating a
  # new instance and calling +service_name+ to access YM services.
  # For example:
  #
  # ym = Yieldmanager::Client(
  #   :user => "bob",
  #   :pass => "secret",
  #   :api_version => "1.30"
  # )
  #
  # ym.session do |token|
  #   currencies = @ym.dictionary.getCurrencies(token)
  # end
  class Client
    # Yieldmanager user
    attr_reader :user
    # Yieldmanager password
    attr_reader :pass
    # Yieldmanager api version (i.e., "1.30")
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
    # * :api_version (required) - Yieldmanager API version (i.e., "1.30")
    # * :env (optional) - Yieldmanager environment "prod" or "test" (defaults to prod)
    def initialize(options = nil)
      unless options && options[:user] && options[:pass] && options[:api_version]
        raise ArgumentError, ":user, :pass and :api_version are required"
      end
      @user = options[:user]
      @pass = options[:pass]
      @api_version = options[:api_version]
      @env = options[:env] ||= "prod"
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
    
    # Opens Yieldmanager session
    def start_session
      contact.login(@user,@pass,{'errors_level' => 'throw_errors','multiple_sessions' => '1'})
    end
    
    # Closes Yieldmanager session
    def end_session token
      contact.logout(token)
    end
    
    # Manages Yieldmanager session
    def session
      token = start_session
      begin
        yield token
      ensure
        end_session token
      end
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
    
    def pull_report xml
      rpt = Yieldmanager::Report.new
      
      rpt
    end

private
    
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
    
    def request_report_token token, xml
      report.requestViaXML(token,xml)
    end
    
    def retrieve_report_url token, report_token
      report_url = nil
      60.times do |secs| # Poll until report ready
        report_url = report.status(token,report_token)
        break if report_url != nil
        sleep(5)
      end
      report_url
    end
  end
end