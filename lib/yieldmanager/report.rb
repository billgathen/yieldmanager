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
    attr_accessor :headers, :data
    
    def initialize
      self.headers = []
      self.data = []
    end
    
    def pull token, report, xml
      report_token = request_report_token token, report, xml
      report_url = retrieve_report_url token, report, report_token
      retrieve_data report_url
    end

    def add_row row_data
      row = ReportRow.new(self)
      row_data.each { |ele| row << ele }
      data << row
    end

private
    
    def request_report_token token, report, xml
      report.requestViaXML(token,xml)
    end

    def retrieve_report_url token, report, report_token
      report_url = nil
      60.times do |secs| # Poll until report ready
        report_url = report.status(token,report_token)
        break if report_url != nil
        sleep(5)
      end
      report_url
    end
    
    def retrieve_data url
      doc = open(url) { |f| Hpricot(f) }
      (doc/"header column").each do |col|
        headers << col.inner_html
      end
      (doc/"row").each_with_index do |row_elems,idx|
        # TODO cast elements to appropriate types based on column attrs
        row = ReportRow.new(self)
        (row_elems/"column").each do |col|
          row << col.inner_html
        end
        data << row
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
