# PromptCloudDataAPI

This is PromptCloud's (promptcloud.com) API gem. It can be used to query indexed data from promptcloud.
NOTE: API query requires a valid userid and password.

For any queries related to this gem, contact data-api-gem@promptcloud.com.

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
#above method will put the downloaded files in ~/promptcloud/downloads
#to override promptcloudhome (~/promptcloud), provide arg- :promptcloudhome=>"complete path of other dir"
#to override download dir provide arg- :download_dir => "<download dir full path>"
#to override conf dir provide arg- :apiconf => "<api conf full path>"

Access using Command line:

get_promptcloud_data -h #will display help
get_promptcloud_data --user <username> --pass <password> [--category <category>] [--timestamp <timestamp>] 
#above command will put the downloaded files in ~/promptcloud/downloads
#log file can be viewed at ~/promptcloud/log/*log
#api config file at ~/promptcloud/configs/config.yml
#to override the downloaded file use option --download_dir "<apidir full path>"
#to override config dir use option --apiconf "<apiconf full path>"

In command line tool, if option --perform_initial_setup is provided along with other options, then initial setup will be performed (create conf file, download dir)

## Contributing
In order to contribute to this gem,

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
