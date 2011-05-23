require 'rubygems'
require 'soap/wsdlDriver'
require 'open-uri'
require 'hpricot'

# 1.8.7 uses Hash#index as the norm, but 1.9.2 uses Hash#key
if RUBY_VERSION[0,3] == "1.9"
  class SOAP::RPC::SOAPMethod
    private
    def init_param(param_def)
      param_def.each do |io_type, name, param_type|
        mapped_class, nsdef, namedef = SOAP::RPC::SOAPMethod.parse_param_type(param_type)
        if nsdef && namedef
          type_qname = XSD::QName.new(nsdef, namedef)
        elsif mapped_class
          # Ruby 1.8.7 way: 
          # type_qname = TypeMap.index(mapped_class)
          # Ruby 1.9.2 way: 
          type_qname = TypeMap.key(mapped_class)
        end
        case io_type
        when IN
          @signature.push([IN, name, type_qname])
          @inparam_names.push(name)
        when OUT
          @signature.push([OUT, name, type_qname])
          @outparam_names.push(name)
        when INOUT
          @signature.push([INOUT, name, type_qname])
          @inoutparam_names.push(name)
        when RETVAL
          if @retval_name
            raise MethodDefinitionError.new('duplicated retval')
          end
          @retval_name = name
          @retval_class_name = mapped_class
        else
          raise MethodDefinitionError.new("unknown type: #{io_type}")
        end
      end
    end
    
  end
end


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
  #     :pass => "secret"
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
    # Yieldmanager api version (i.e., "1.33")
    attr_reader :api_version
    # Yieldmanager environment ("prod" or "test", defaults to "prod")
    attr_reader :env
    
    AVAILABLE_ENVS = ["test","prod"]
    BASE_URL = "https://api.yieldmanager.com/api-"
    BASE_URL_TEST = "https://api-test.yieldmanager.com/api-"
    WSDL_DIR = File.join(File.dirname(__FILE__), '..', '..', 'wsdls')
  
    # Creates interface object.
    #
    # Options:
    # * :user (required) - Yieldmanager user
    # * :pass (required) - Yieldmanager pass
    # * :env (optional) - Yieldmanager environment "prod" or "test" (defaults to prod)
    def initialize(options = {})
      @user = options[:user] ||= options['user']
      @pass = options[:pass] ||= options['pass']
      raise ArgumentError, ":user and :pass are required" unless @user && @pass
      
      @api_version = Yieldmanager::Client.api_version
      
      @env = (options[:env] || options['env'] || "prod")
      raise ArgumentError, ":env must be 'test' or 'prod', was #{@env.inspect}" unless AVAILABLE_ENVS.include?(@env)
      
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
    def pull_report token, xml, report_response_format = "xml"
      report = Yieldmanager::Report.new
      report.pull(token, self.report, xml, report_response_format)
      report
    end

    def self.api_version
      version_file = "API_VERSION"
      path = File.join(File.dirname(__FILE__), '..', '..', version_file)
      unless File.exists?(path)
        fail "Put the API version in a file called #{version_file}"
      end
      File.open(path){ |f| f.readline.chomp }
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
