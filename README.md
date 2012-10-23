# PromptCloudDataAPI

This is PromptCloud's (http://promptcloud.com) data  API gem. It can be used to fetch the client specific data from PromptCloud data api.

NOTE: API query  requires a valid userid and password.

For queries related to this gem please contact the folks at promptcloud or open a github issue

## Installation
Option 1-
Add this line to your application's Gemfile:

    gem 'promptcloud_data_api'

And then execute:

    $ bundle

Option 2-
Directly install using:

    $ gem install promptcloud_data_api

## Usage

Access using program:

require 'promptcloud_data_api'
obj=PromptCloudApi.new
obj.download_files({:user => "<your valid user name>", :pass => "<your valid password>", :timestamp=> <timestamp>[optional], :category=> "<category>"[optional]})

* Above method will put the downloaded files in ~/promptcloud/downloads
* To override promptcloudhome (~/promptcloud), provide arg- :promptcloudhome=>"complete path of other dir"
* To override download dir provide arg- :download_dir => "<download dir full path>"
* To override conf dir provide arg- :apiconf => "<api conf full path>"

Access using Command line:

get_promptcloud_data -h #will display help
get_promptcloud_data --user <username> --pass <password> [--category <category>] [--timestamp <timestamp>] 

* Above command will put the downloaded files in ~/promptcloud/downloads
* Log file can be viewed at ~/promptcloud/log/*log
* Api config file at ~/promptcloud/configs/config.yml
* To override the downloaded file use option --download_dir "<apidir full path>"
* To override config dir use option --apiconf "<apiconf full path>"

In command line tool, if option --perform_initial_setup is provided along with other options, then initial setup will be performed (create conf file, download dir)

## Contributing
In order to contribute to this gem,

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
