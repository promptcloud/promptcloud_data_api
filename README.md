# PromptCloudDataAPI

This is PromptCloud's (http://promptcloud.com) data API gem. It can be used to fetch the client specific data from PromptCloud data API. Available data API version are v1 and v2.  

Note: 
* API v1 requires valid userid and password.
* API v2 requires userid and authentication key.

PromptCloud provides userid and password/authentication key.  

For queries related to this gem please contact the folks at promptcloud or open a github issue.

## Installation
#### Option 1
Add this line to your application's Gemfile:

    gem 'promptcloud_data_api'

And then execute:

    $ bundle

#### Option 2
Directly install using:

    $ gem install promptcloud_data_api

## Usage

#### Access using program

require 'promptcloud_data_api'

obj = PromptCloudApi.new({:user => "your valid user name", :pass => "your valid password"}) # API v1

obj = PromptCloudApi.new({:user => "your valid user name", :client_auth_key => "your valid auth key"}) # API v2

obj.download_files({:timestamp => "timestamp"[optional], :category => "category"[optional], :site => "site name"[optional]})

#### Access using command line

get_promptcloud_data -h #will display help

get_promptcloud_data --user "username" --pass "password" [--category "category"] [--timestamp "timestamp"] # API v1 

get_promptcloud_data --api_version v2  --user "username" --client_auth_kay "auth key" [--category "category"] [--timestamp "timestamp"] # API v2

* The downloaded files will be put in ~/promptcloud/downloads
* To override download di, provide arg - :download_dir => "download dir full path"
* To override defalut promptcloudhome(~/promptcloud), provide arg - :promptcloudhome => "complete path of other dir"
* API config file at ~/promptcloud/configs/config.yml
* To override conf dir provide arg - :apiconf => "api conf full path"
* Log file can be viewed at ~/promptcloud/log/*log

In command line tool, if option --perform_initial_setup is provided along with other options, then initial setup will be performed (create conf file, download dir).

## Contributing
In order to contribute to this gem -

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request
