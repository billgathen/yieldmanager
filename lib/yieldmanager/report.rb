# Patch bogus SSL_CONNECT error in retrieve_data
# via KarateCode[https://github.com/KarateCode] (Michael Schneider)
#
require 'openssl'
require 'fastercsv' if RUBY_VERSION[0,3] != "1.9"

module OpenSSL
  module SSL
    remove_const :VERIFY_PEER
  end
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
#
#

module Yieldmanager
  # This is the data object for all reportware requests.
  #
  # The #pull method is typically called by Yieldmanager::Client#pull_report.
  #
  # Data is returned as an array that can be accessed either by index
  # or by column name:
  #
  #   report.headers # => ['advertiser_name','seller_imps']
  #   report.data[0][0] # => "Bob's Ads"
  #   report.data[0].by_name('advertiser_name') # => "Bob's Ads"
  #   report.data[0].by_name(:advertiser_name) # => "Bob's Ads"
  # 
  # Column order is stored in the *headers* array.
  class Report
    attr_accessor :headers, :data, :is_a_csv_report
    
    def initialize
      self.headers = []
      self.data = []
    end
    
    def pull token, report, xml, is_csv = false
      self.is_a_csv_report = is_csv
      report_token = request_report_token token, report, xml
      report_url = retrieve_report_url token, report, report_token
      retrieve_data report_url
    end

    def add_row row_data
      row = ReportRow.new(self)
      row_data.each { |ele| row << ele }
      data << row
    end

    def to_hashes
      hashes = []
      data.each do |row|
        row_hash = {}
        row.each_with_index do |ele,idx|
          row_hash[headers[idx]] = ele
        end
        hashes << row_hash
      end
      hashes
    end

private
    
    def request_report_token token, report, xml
      report.requestViaXML(token,xml)
    end

    def retrieve_report_url token, report, report_token
      report_url = nil
      120.times do |secs| # Poll until report ready
        report_url = report.status(token,report_token)
        break if report_url != nil
        sleep(5)
      end
      raise "ReportWare url is blank" if report_url.nil? || report_url.empty?
      report_url
    end
    
    def retrieve_data url
      second_pull_attempt = false
      begin
        doc = open(url)
      rescue OpenURI::HTTPError => the_error
        raise the_error if second_pull_attempt
        raise the_error unless the_error.io.status.first == "404"
        
        # sleep 10 seconds while we wait for reportware to place the report at the destination url
        sleep(10)
        second_pull_attempt = true
        retry
      end
      
      if is_a_csv_report
        data_set = FasterCSV.read(doc.path)
        self.headers = data_set.shift.split(",")
        data_set[0,data_set.size-3].each do |csv_row| # the three junk lines at the end of the report
          row = ReportRow.new(self)
          csv_row.each do |col|
            row << col
          end
          self.data << row
        end
      else        
        doc = Hpricot(doc)
        (doc/"header column").each do |col|
          self.headers << col.inner_html
        end
        (doc/"row").each do |row_elems|
          # TODO cast elements to appropriate types based on column attrs
        
          row = ReportRow.new(self)
          (row_elems/"column").each do |col|
            row << col.inner_html
          end
          self.data << row
        end
      end
    end
    
    class ReportRow < Array
      def initialize report
        @report = report
      end
      
      def by_name name
        idx = @report.headers.index(name.to_s)
        raise ArgumentError.new("Column not found: '#{name}'") if idx.nil?
        at(idx)
      end
    end
  end

end
