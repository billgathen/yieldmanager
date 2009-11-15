require 'open-uri'
require 'ftools'
require 'fileutils'

module Yieldmanager
  class Builder
    TEST = true
    BASE_URL = "https://api.yieldmanager.com/api-"
    BASE_URL_TEST = "https://api-test.yieldmanager.com/api-"
    WSDL_DIR = File.join(File.dirname(__FILE__), '..', '..', 'wsdls')
    def self.build_wsdls_for api_version
      unless api_version.match(/^\d\.\d{2}/)
        raise ArgumentError, "Non-standard api version"
      end
      build_dirs_for api_version
      store_wsdls(BASE_URL, api_version, lookup_services(api_version))
      store_wsdls(BASE_URL_TEST, api_version, lookup_services(api_version), TEST)
    end
    
    def self.build_dirs_for api_version
      ["test","prod"].each do |env|
        dir = "#{WSDL_DIR}/#{api_version}/#{env}"
        if File.exists?(dir)
          FileUtils.rm_rf dir
        end
        File.makedirs(dir)
      end
    end
    
    def self.lookup_services api_version, test = false
      services = []
      base_url = test ? BASE_URL_TEST : BASE_URL
      open("#{base_url}#{api_version}/xsd_gen.php?wsdl") do |f|
        f.each_line do |line|
          if line.match(/xmlns:api=".*\/(\w+)Service"/)
            services << camel_to_under($1) unless $1 == "CPMFloor"
          end
        end
      end
      services
    end
    
    def self.store_wsdls base_url, api_version, services, test = false
      wsdl_path = "#{WSDL_DIR}/#{api_version}/#{test ? 'test' : 'prod'}"
      services.each do |s|
        service_url = "#{base_url}#{api_version}/#{s}.php?wsdl"
        open(service_url) do |f|
          File.open("#{wsdl_path}/#{s}.wsdl","w") do |wsdl_file|
            f.each_line { |l| wsdl_file.write(l) }
          end
        end
      end
    end
    
    def self.camel_to_under s
      s.gsub(/(.)([A-Z])/,'\1_\2').downcase
    end
  end
end
