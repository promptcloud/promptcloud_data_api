# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'promptcloud_data_api/version'

Gem::Specification.new do |gem|
  gem.name          = "promptcloud_data_api"
  gem.version       = PromptcloudDataApi::VERSION
  gem.authors       = ["PromptCloud"]
  gem.email         = ["promptcloud-data-api@promptcloud.com"]
  gem.description   = %q{This gem can be used to download data from Promptcloud data API. You need to be PromptCloud client to get the data though :)}
  gem.summary       = %q{use it to query promptcloud indexed data}
  gem.homepage      = "http://promptcloud.com"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "rest-client"
end
