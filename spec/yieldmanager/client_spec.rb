require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "A new Yieldmanager client" do
  before(:each) do
    @ym = Yieldmanager::Client.new(login_args)
  end
  
  it "requires :user, :pass and :api_version as args" do
    @ym.user.should equal(login_args[:user])
    @ym.pass.should equal(login_args[:pass])
    @ym.api_version.should equal(login_args[:api_version])
    lambda { Yieldmanager::Client.new() }.should raise_error(ArgumentError)
    lambda { Yieldmanager::Client.new({}) }.should raise_error(ArgumentError)
  end
  
  it "defaults to prod, accepts override to test" do
    @ym.env.should == "prod"
    ym_test = Yieldmanager::Client.new(login_args.merge(:env => "test"))
    ym_test.env.should == "test"
  end
  
  it "displays available services" do
    @ym.available_services.should include("contact")
    ym_test = Yieldmanager::Client.new(login_args.merge(:env => "test"))
    ym_test.available_services.should include("contact")
  end
  
  def login_args
    @login_args ||= {
      :user => "bill",
      :pass => "secret",
      :api_version => "1.30"
    }
  end
end
