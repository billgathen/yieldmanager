# yieldmanager

[![Build Status](https://travis-ci.org/billgathen/yieldmanager.png)](https://travis-ci.org/billgathen/yieldmanager)

This gem offers read/write access to [YieldManager's API tools](https://api.yieldmanager.com/doc/) and
ad-hoc reporting through the Reportware tool.

Currently it generates a fresh wsdl from the api.yieldmanager.com site the
first time you use a service (in the future it will use locally-cached
copies) and re-uses that wsdl for the life of the Yieldmanager::Client object.

The current API version is stored in the API_VERSION file.

The gem should run properly on 1.8, 1.9, 2.0 and JRuby 1.7.4, but 1.8 support will likely be removed in a future version.

### Installation

Yieldmanager is available as a gem for easy installation.

```
sudo gem install yieldmanager
```

or if you're using [RVM](https://rvm.beginrescueend.com/) (and why on earth wouldn't you?)

```
gem install yieldmanager
```

The project is available for review/forking on github.com

```
git clone git://github.com/billgathen/yieldmanager.git
```

To use in a Rails project, add this to config/environment.rb:

```ruby
config.gem 'yieldmanager'
```

### Creating a Yieldmanager::Client

```ruby
require 'yieldmanager'

@ym = Yieldmanager::Client.new(
	:user => "bob",
	:pass => "secret"
)
```

The default environment is production.
To access the test environment, use this:

```ruby
@ym = Yieldmanager::Client.new(
	:user => "bob",
	:pass => "secret",
	:env => "test"
)
```

The keys can also be passed as strings: 'user', 'pass' and 'env'.

**NOTE** Changing the environment after creation has no effect!

### What API version am I using?

To check (or log) the current API version, execute the following:

```ruby
Yieldmanager::Client.api_version
```

### Finding available services

```ruby
@ym.available_services
```

### Using a service

```ruby
@ym.session do |token|
	@currencies = @ym.dictionary.getCurrencies(token)
end
```

**GOTCHA** In projects with ActiveRecord enabled (i.e., Rails projects)
SOAP will identify returned data as AR objects if there's a
naming collision. For example, if you're running

```ruby
@ym.creative.get(token,123)
```

and you have an AR objects for a **creatives** table in the db, the
SOAP parser will interpret the returned SOAP object as
an AR Creative object, resulting in bizarre errors. Uniquely
re-name your AR object to eliminate the conflict.

### Pagination

Some calls return datasets too large to retrieve all at once.
Pagination allows you to pull them back incrementally, handling
the partial dataset on-the-fly or accumulating it for later use.

```ruby
BLOCK_SIZE = 50
id = 1
@ym.session do |token|
	@ym.paginate(BLOCK_SIZE) do |block|
		(lines,tot) = @ym.line_item.getByBuyer(token,id,BLOCK_SIZE,block)
		# ...do something with lines...
		tot # remember to return total!
	end
end
```


### Pulling reports

Accessing reportware assumes you've used the "Get request XML"
functionality in the UI to get your request XML, or have
crafted one from scratch. Assuming it's in a variable called
**request_xml**, you'd access the data this way:

```ruby
@ym.session do |token|
	report = @ym.pull_report(token, request_xml)
	puts report.headers.join("\t")
	report.data.each do |row|
		puts row.join("\t")
	end
end
```

For large reports it may be necessary to increase the request
timeout, which has a default value of 300 seconds. You may do
so by passing in an additional argument to **pull_report**:

```ruby
max_wait_seconds = 600
@ym.pull_report(token, request_xml, max_wait_seconds)
```

Column data can be accessed either by index or column name:

```ruby
report.headers # => ['advertiser_name','seller_imps']
report.data[0][0] # => "Bob's Ads"
report.data[0].by_name('advertiser_name') # => "Bob's Ads"
report.data[0].by_name(:advertiser_name) # => "Bob's Ads"
```

If you call **by_name** with a non-existent column, it will throw an
**ArgumentError** telling you so.

Or you can extract the report to an array of named hashes, removing
dependencies on the gem for consumers of the data (say, across an API):

```ruby
hashes = report.to_hashes
hashes[0]['advertiser_name'] # => "Bob's Ads"
```

**NOTE** Any totals columns your xml requests will be interpreted
as ordinary data.

### Mocking reports

When simulating report calls without actually hitting Yieldmanager, you can
create your own reports.

```ruby
rpt = Yieldmanager::Report.new
rpt.headers = ["first","second"]
rpt.add_row([1,2])
rpt.data.first.by_name("first").should == 1
rpt.data.first.by_name("second").should == 2
```

### Wiredumps (SOAP logging)

To see the nitty-gritty of what's going over the wire (Yahoo tech support often asks for this),
you can activate a "wiredump" on a per-service basis. Typically you just echo it to standard out.
For instance:

```ruby
client.entity.wiredump_dev = $stdout # on
adv = client.entity.get(token,12345)
client.entity.wiredump_dev = nil # off
```

For Rails in a passenger environment, standard out doesn't end up in the logfiles.
Instead, redirect to a file:

```ruby
wiredump = File.new("#{Rails.root}/log/wiredump_entity_#{Time.new.strftime('%H%M%S')}.log",'w')
client.entity.wiredump_dev = wiredump # on

adv = client.entity.get(token,12345)

wiredump.flush # make sure everything gets in there before it closes
client.entity.wiredump_dev = nil # off
```

The last 2 lines belong in an ensure block, so the file is created even
when there's an error (which is probably why you're doing this).

### session vs. start_session/end_session

The **session** method opens a session, gives you a token to use in your service
calls, then closes the session when the block ends, even if an exception is
raised during processing. It's the recommended method to ensure you don't
hang connections when things go wrong. If you use start/end, make sure you
wrap your logic in a begin/ensure clause and call end_session from the ensure.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add specs for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but
  bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Thanks for contributing!
* [manlycode](https://github.com/manlycode)
* [KarateCode](https://github.com/KarateCode)
* [budnik](https://github.com/budnik) 
* [walsh1kt](http://github.com/walsh1kt)

## Copyright

Copyright (c) 2009-2012 Bill Gathen. See LICENSE for details.
