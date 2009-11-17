require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

NEED_ENV_ARGS_MSG = <<EOM
Please set these environment variables to match your Yieldmanager account:
* YIELDMANAGER_USER
* YIELDMANAGER_PASS
* YIELDMANAGER_API_VERSION
EOM

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
  
  it "exposes helper methods for available services" do
    @ym.contact.should be_instance_of(SOAP::RPC::Driver)
  end
  
  it "generates contact service supporting login/logout of session" do
    token = @ym.contact.login(@login_args[:user],@login_args[:pass],{'errors_level' => 'throw_errors','multiple_sessions' => '1'})
    begin
      token.should_not be_nil
    ensure
      @ym.contact.logout(token)
    end
  end
  
  it "exposes start/end session" do
    token = @ym.start_session
    currencies = @ym.dictionary.getCurrencies(token)
    @ym.end_session token
    lambda { @ym.dictionary.getCurrencies(token) }.should raise_error(SOAP::FaultError)
  end
  
  it "exposes session block" do
    my_token = nil
    @ym.session do |token|
      my_token = token
      currencies = @ym.dictionary.getCurrencies(token)
    end
    lambda { @ym.dictionary.getCurrencies(my_token) }.should raise_error(SOAP::FaultError)
  end
  
  it "closes a session even after an exception" do
    my_token = nil
    lambda do
      @ym.session do |token|
        my_token = token
        raise Exception, "Ouch!"
      end
    end.should raise_error(Exception)
    lambda { @ym.dictionary.getCurrencies(my_token) }.should raise_error(SOAP::FaultError)
  end
  
  def login_args
    unless ENV["YIELDMANAGER_USER"] &&
      ENV["YIELDMANAGER_PASS"] &&
      ENV["YIELDMANAGER_API_VERSION"]
      raise(ArgumentError, NEED_ENV_ARGS_MSG)
    end
    @login_args ||= {
      :user => ENV["YIELDMANAGER_USER"],
      :pass => ENV["YIELDMANAGER_PASS"],
      :api_version => ENV["YIELDMANAGER_API_VERSION"]
    }
  end
end
