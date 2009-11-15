require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "A new Yieldmanager client" do
  before(:each) do
    @ym = Yieldmanager::Client.new(login_args)
  end
  
  it "requires :user, :pass and :base_url as args" do
    @ym.user.should equal(login_args[:user])
    @ym.pass.should equal(login_args[:pass])
    @ym.base_url.should equal(login_args[:base_url])
    lambda { Yieldmanager::Client.new() }.should raise_error(ArgumentError)
    lambda { Yieldmanager::Client.new({}) }.should raise_error(ArgumentError)
  end
  
  it "ensures :base_url always includes a trailing slash" do
    @ym.base_url.should match(/\/$/)
  end
  
  it "displays available services" do
    @ym.services.should include("contact")
  end
  
  def login_args
    @login_args ||= {
      :user => "bill",
      :pass => "secret",
      :base_url => "https://api.yieldmanager.com/api-1.30"
    }
  end
end
