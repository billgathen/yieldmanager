require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "A build run" do
  it "accepts api version" do
    Yieldmanager::Builder.build_wsdls_for("1.30")
  end
end