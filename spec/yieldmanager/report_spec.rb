require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

NEED_ENV_ARGS_MSG = <<EOM
Please set these environment variables to match your Yieldmanager account:
* YIELDMANAGER_USER
* YIELDMANAGER_PASS
* YIELDMANAGER_API_VERSION
* YIELDMANAGER_CONTACT_ID
* YIELDMANAGER_IP_ADDRESS (your external IP address)
EOM
  
describe "A Yieldmanager report request" do

  before(:each) do
    @ym = Yieldmanager::Client.new(login_args)
  end
  
  it "returns report object" do
    rpt = @ym.pull_report(request_xml)
    rpt.should be_instance_of(Yieldmanager::Report)
  end
  
  it "makes request and returns report token" do
    @ym.session do |token|
      @ym.send(:request_report_token, token,request_xml).should_not be_nil
    end
  end
  
  it "uses report token to pull report url" do
    @ym.session do |token|
      report_token = @ym.send(:request_report_token, token, request_xml)
      report_url = @ym.send(:retrieve_report_url, token, report_token)
      report_url.should_not be_nil
    end
  end
  
  it "throws ReportTimeoutException if report data never returns" do
    # need configurable pause and attempts to keep this from running 5 mins!
    pending
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
    unless ENV["YIELDMANAGER_CONTACT_ID"] &&
      ENV["YIELDMANAGER_IP_ADDRESS"]
      raise(ArgumentError, NEED_ENV_ARGS_MSG)
    end
    <<EOR
<?xml version="1.0"?>
<RWRequest clientName="ui.ent.prod">
  <REQUEST domain="network" service="ComplexReport" nocache="n" contact_id="#{ENV['YIELDMANAGER_CONTACT_ID']}" remote_ip_address="#{ENV['YIELDMANAGER_IP_ADDRESS']}" entity="3" filter_entity_id="3" timezone="EST">
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
