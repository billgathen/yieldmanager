require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "A build run" do
  WSDL_DIR = File.join(File.dirname(__FILE__), '..', '..', 'wsdls')
  API_VERSION = "1.30"
  VERSION_DIR = "#{WSDL_DIR}/#{API_VERSION}"
  
  before(:each) do
    @services = Yieldmanager::Builder.build_wsdls_for(API_VERSION)
  end
  
  it "creates dir structure for new api version" do
    File.directory?("#{VERSION_DIR}").should be_true
    File.directory?("#{VERSION_DIR}/test").should be_true
    File.directory?("#{VERSION_DIR}/prod").should be_true
  end
  
  it "clears out old wsdls" do
    ["test","prod"].each do |env|
      dir = "#{WSDL_DIR}/#{API_VERSION}/#{env}"
      bad_wsdl = "#{dir}/bad.wsdl"
      File.makedirs(dir)
      File.open(bad_wsdl, "w") { |file| file.write("bad.wsdl")  }
      Yieldmanager::Builder.build_wsdls_for(API_VERSION)
      File.exists?(bad_wsdl).should be_false
    end
  end
  
  it "collects available services" do
    TEST = true
    Yieldmanager::Builder.lookup_services(API_VERSION).should include("contact")
    Yieldmanager::Builder.lookup_services(API_VERSION, TEST).should include("contact")
  end
  
  it "stores wsdls" do
    @services.each do |service|
      File.exists?("#{VERSION_DIR}/prod/#{service}.wsdl").should be_true
      File.exists?("#{VERSION_DIR}/test/#{service}.wsdl").should be_true
    end
  end
end