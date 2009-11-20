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
  
  it "paginates" do
    BLOCK_SIZE = 50
    id = -1
    @ym.session do |token|
      line_item_service = @ym.line_item
      [
        {:calls_expected => 2, :dataset_size => 75},
        {:calls_expected => 1, :dataset_size => 25},
        {:calls_expected => 1, :dataset_size => 0}
      ].each do |args|
        line_item_service.
          should_receive(:getByBuyer).
          exactly(args[:calls_expected]).times.
          and_return([[],args[:dataset_size]])
        @ym.paginate(BLOCK_SIZE) do |block|
          (lines,tot) = line_item_service.
            getByBuyer(token,id,BLOCK_SIZE,block)
          # must return total rows in dataset
          # so paginate knows when to stop!
          tot
        end
      end
    end
  end
  
  describe "A Yieldmanager report" do

    before(:each) do
      @ym = Yieldmanager::Client.new(login_args)
    end
    
    it "returns data" do
      request_xml.should include("advertiser_id")
    end
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

  def request_xml
    <<EOR
<?xml version="1.0"?>
<RWRequest clientName="ui.ent.prod">
  <REQUEST domain="network" service="ComplexReport" nocache="n" contact_id="52798" remote_ip_address="99.62.255.163" entity="3" filter_entity_id="3" timezone="EST">
    <ROWS>
      <ROW type="group" priority="1" ref="entity_id" includeascolumn="n"/>
      <ROW type="group" priority="2" ref="advertiser_id" includeascolumn="n"/>
      <ROW type="total"/>
    </ROWS>
    <COLUMNS>
      <COLUMN ref="advertiser_name"/>
      <COLUMN ref="seller_imps"/>
    </COLUMNS>
    <FILTERS>
      <FILTER ref="time" macro="yesterday"/>
    </FILTERS>
  </REQUEST>
</RWRequest>
EOR
  end
end
