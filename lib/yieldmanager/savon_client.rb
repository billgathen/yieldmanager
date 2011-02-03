require 'savon'

LoginArgs = {
  :user => ENV['YIELDMANAGER_USER'],
  :pass => ENV['YIELDMANAGER_PASS'],
  :api_version => ENV['YIELDMANAGER_API_VERSION']
}

LoginOptions = {
  :errors_level => 'throw_errors',
  :multiple_sessions => '1'
}

contact = Savon::Client.new { wsdl.document = "https://api-test.yieldmanager.com/api-1.32/contact.php?wsdl" }
entity = Savon::Client.new { wsdl.document = "https://api-test.yieldmanager.com/api-1.32/entity.php?wsdl" }

rsp = contact.request :login do
  soap.body = { :user => LoginArgs[:user], :pass => LoginArgs[:pass], :login_options => LoginOptions }
end
token = rsp.to_hash[:login_response][:token]

begin
  rsp = entity.request :get do
    soap.body = { :token => token, :id => 25008 }
  end
  y rsp.header
  hdr = rsp.header
  puts "#{hdr[:command_group]} #{hdr[:quota_type]} quota: #{hdr[:quota_used_so_far]} used, #{hdr[:remaining_quota]} remaining"
  entity = rsp.to_hash[:get_response][:entity]
  puts "#{entity[:name]} (#{entity[:id]})"
ensure
  contact.request :logout do
    soap.body = { :token => token }
  end
end
