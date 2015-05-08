# PromptCloudDataAPI

This is [PromptCloud's](http://promptcloud.com) data API gem. It can be used to fetch the client specific data from PromptCloud data API. Available data API version are v1 and v2.  

## Installation
#### Option 1
Add this line to your application's Gemfile:

    gem 'promptcloud_data_api'

And then execute:

    $ bundle

#### Option 2
Directly install using:

    $ gem install promptcloud_data_api

## Usage: ./get_promptcloud_data [options] 

    -v, --api_version VERSION        to get data from different api version(available versions are v1 and v2, the defalut version is v1)
    -u, --user USER                  data api user id(provided by PromptCloud)
    -p, --pass PASSWORD              data api password(provised by PromptCloud, used for api v1)
    -k, --client_auth_key AUTHKEY    data api client auth key(provided by PromptCloud, used for api v2)
    -i, --perform_initial_setup      to perform initial setup
        --display_info               to display config info
        --apiconf APICONFPATH        to override the config file path(config file stores information like client_id, password, client_auth_key, downloadir etc)
        --download_dir DOWNLOAD_DIRECTORY
                                     to override the download dir(which contains downloaded data files)
        --promptcloudhome PROMPTCLOUDHOME
                                     to override the promptcloudhome dir(~/promptcloud)
    -t, --timestamp TIMESTAMP        to query promptcloud api for files newer than or equal to given timestamp
        --days DAYS                  to download the data of last few days
        --hours DAYS                 to download the data of last few hours
        --minutes MINUTES            to download the data last few minutes
        --queried_timestamp_file queried TIMESTAMPFILE
                                     to override the last timestamp file(contains last queried timestamp)
        --category CATEGORY          to query promptcloud api for files of the given category(if files of different verticals are placed in different directory under client's parent directory, then files of specific directory can be obtained by specifying that directory name in category option)
        --site SITE_NAME             to query promptcloud api for files of the given site
        --loop                       download new data files and keep looking for new one(i.e it doesn't exit, if no new feed is found it will sleep, minimun sleep time is 10 secs and max sleep time is 300 secs)
        --noloop                     download new data files and and exit, this is the default behaviour
        --bcp                        to download data from PromptCloud backup server(high availability server, should use if main data api server is unreachable)
    -h, --help                       Show this message

####Note 

* API v1 requires valid userid and password.
* API v2 requires userid and authentication key.
* PromptCloud provides userid and password/authentication key to the client.  
* If option --perform_initial_setup is provided along with other options, then initial setup will be performed(create conf file, download dir).
* If we do not pass any of --timestamp, --days, --hours and --minutes, then past 2 days data will be downloaded(default setting).

For queries related to this gem please contact the folks at promptcloud or open a github issue.

#### API Help Links 
API v1: [https://api.promptcloud.com/data/info?type=help](https://api.promptcloud.com/data/info?type=help)

API v2: [https://api.promptcloud.com/v2/data/info?type=help](https://api.promptcloud.com/data/info?type=help)

#### Access using program

require 'promptcloud_data_api'

For API v1

    obj = PromptCloudApi.new({--perform_initial_setup, :user => "your valid user name", :pass => "your valid password"})

For API v2

    obj = PromptCloudApi.new({--perform_initial_setup, :user => "your valid user name", :client_auth_key => "your valid auth key"})

To download data files 

    obj.download_files({:timestamp => "timestamp"[optional], :category => "category"[optional], :site => "site name"[optional]})

#### Access using command line

For API v1

    get_promptcloud_data --perform_initial_setup --user "username" --pass "password"
    
    get_promptcloud_data [--category "category"] [--timestamp "timestamp"]

For API v2

    get_promptcloud_data --api_version v2  --perform_initial_setup --user "username" --client_auth_kay "auth key"
    
    get_promptcloud_data --api_version v2 [--category "category"] [--timestamp "timestamp"] # API v2

## Contributing
In order to contribute to this gem -

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new pull request
