require File.dirname(File.expand_path(__FILE__)) + "/promptcloud_data_api/version"


require 'rexml/document'
require 'open-uri'
require 'optparse'
require 'fileutils'
require 'restclient'
require 'yaml'
require 'digest/md5'



class PromptCloudApi
	@@promptcloudhome="#{ENV["HOME"]}/promptcloud/"
	attr_accessor :api_downtime
	
	def initialize(args_hash = {})
		super()
		@download_dir = nil
		@client_id = nil
		@password = nil
		@client_auth_key = nil
		perform_initial_setup(args_hash)
	end

	def display_info(args_hash)
		apiconf = "#{@@promptcloudhome}/configs/config.yml"
		apiconf = args_hash[:apiconf] if args_hash[:apiconf]
		if File.file?(apiconf)
			conf_hash = YAML::load_file(apiconf)
			conf_hash.each_pair do |key, val|
				puts "#{key} : #{val}"
			end
		else
			$stderr.puts "Config file #{apiconf} doesn't exist, use -i to create config file"
		end
	end
	
	#optional argument args_hash={:promptcloudhome=>..., :apiconf=>...., :queried_timestamp_file=>}
	def perform_initial_setup(args_hash={})
		@@promptcloudhome = args_hash[:promptcloudhome] if args_hash[:promptcloudhome]
		FileUtils.mkdir_p(@@promptcloudhome) unless File.directory?(@@promptcloudhome)
		
		args_hash[:apiconf] = "#{@@promptcloudhome}/configs/config.yml" unless args_hash[:apiconf]
		FileUtils.mkdir_p(File.dirname(args_hash[:apiconf])) unless File.directory?(File.dirname(args_hash[:apiconf]))
		
		args_hash[:log_dir]="#{@@promptcloudhome}/log" unless args_hash[:log_dir]
		FileUtils.mkdir_p(args_hash[:log_dir]) unless File.directory?(args_hash[:log_dir])
		
		args_hash[:md5_dir]="#{@@promptcloudhome}/md5sums" unless args_hash[:md5_dir]
		FileUtils.mkdir_p(args_hash[:md5_dir]) unless File.directory?(args_hash[:md5_dir])
		
		args_hash[:queried_timestamp_file]="#{@@promptcloudhome}/last_queried_ts" unless args_hash[:queried_timestamp_file]
		
		args_hash["download_dir"] = File.join(@@promptcloudhome, "downloads") unless args_hash["download_dir"]
		@download_dir = args_hash["download_dir"]
		FileUtils.mkdir_p(@download_dir) unless File.directory?(@download_dir)

		@conf_hash = {}
		if File.file?(args_hash[:apiconf])
			conf_hash = YAML::load_file(args_hash[:apiconf])
			@conf_hash = conf_hash if conf_hash and conf_hash.is_a?Hash
			@client_id = @conf_hash["client_id"]
			if args_hash[:api_version] == "v2"
				@client_auth_key = @conf_hash["client_auth_key"]
			else
				@password = @conf_hash["password"]
			end
		end
		@client_id = args_hash[:user] if args_hash[:user]
		@client_auth_key = args_hash[:client_auth_key] if args_hash[:client_auth_key]
		@password = args_hash[:pass] if args_hash[:pass]
		unless @client_id	
			$stdout.print "\nPlease enter the user id(for example if you use url http://api.promptcloud.com/data/info?id=demo, then your user id is demo)\n:"
			@client_id = STDIN.gets.chomp.strip
		end
		if args_hash[:api_version] == "v2"
			unless @client_auth_key
				$stdout.print "\nPlease enter the auth key(Provided by PromptCloud)\n:"
				@client_auth_key = STDIN.gets.chomp.strip
			end
		else
			unless @password
				$stdout.print "\nPlease enter the password(Provided by PromptCloud)\n:"
				@password = STDIN.gets.chomp.strip
			end
		end	
		@conf_hash["client_id"] = @client_id
		@conf_hash["client_auth_key"] = @client_auth_key if args_hash[:api_version] == "v2"
		@conf_hash["password"] = @password if args_hash[:api_version] == "v1"
		@conf_hash["download_dir"] = @download_dir
		File.open(args_hash[:apiconf], "w") do |file|
			file << @conf_hash.to_yaml
		end
	end

	def download_files(args_hash)
		new_feed_exists = false
		ts = ("%10.9f" % (Time.now).to_f).to_s.gsub(/\./, "").to_i
		fetch_log = "#{args_hash[:log_dir]}/fetched_urls-#{ts}.log"
		fetch_log_file = File.open(fetch_log, "w")
		ts_urls_map, url_md5_map = get_file_urls(args_hash)
		unless ts_urls_map
			$stderr.puts "Could not obtain file urls to download."
			return new_feed_exists
		end
		if ts_urls_map.keys.empty?
			$stderr.puts "No new files to download"
			return new_feed_exists
		end
		sorted_ts = ts_urls_map.keys.sort
		sorted_ts.each do |ts|
			urls = ts_urls_map[ts]
			next if not urls
			urls.each do |url|
				md5sum = url_md5_map[url]
				filename = File.basename(url)
				md5_filename = filename.gsub(/\.gz/, ".md5sum")
				md5_filepath = args_hash[:md5_dir]+ "/#{md5_filename}"
				if File.file?(md5_filepath) and File.open(md5_filepath).read.chomp.strip == md5sum
					$stderr.puts "Skipping file #{url}, it has been downloaded earlier."
					next
				end
				new_feed_exists = true
				begin
					$stderr.puts "Fetching file #{url}"
					req = RestClient::Request.new({:method => "get", :user => @client_id, :password => @password, :url =>url}) if args_hash[:api_version] == "v1"
					req = RestClient::Request.new({:method=>"get", :url =>url}) if args_hash[:api_version] == "v2"
					outfile = File.join(@download_dir, File.basename(url))
					File.open(outfile, "wb") do |file|
						file.write req.execute
					end
					content = ""
					Zlib::GzipReader.open(outfile) {|gz|
						content = gz.read
					}
					downloaded_md5 = Digest::MD5.hexdigest(content)
					if md5sum == downloaded_md5
						File.open(md5_filepath, "w"){|file| file.puts md5sum}
						fetch_log_file << "Fetched: #{url}"
					else
						$stderr.puts "Url : #{url} was not downloaded completely, hence deleting the downloaded file"
						fetch_log_file.puts "Failed: #{url}"
						File.delete(outfile)
					end
				rescue Exception => e
					$stderr.puts "Failed to fetch url: #{url}, Exception: #{e.class}, #{e.message}"
					fetch_log_file.puts "Failed: #{url}"
				end
			end
		end
		fetch_log_file.close
		$stderr.puts "\nLog file : #{fetch_log}"
		$stderr.puts "Downloaded files are available at : #{@download_dir}\n\n"
		return new_feed_exists
	end

	private
	def get_api_url(args_hash)
		base_url = "https://api.promptcloud.com"
		base_url = "https://api.bcp.promptcloud.com" if args_hash[:bcp]
		promptcloud_api_url = base_url + "/data/info?id=#{@client_id}" if args_hash[:api_version] == "v1"
		promptcloud_api_url = base_url + "/v2/data/info?id=#{@client_id}&client_auth_key=#{@client_auth_key}" if args_hash[:api_version] == "v2"
		if args_hash[:timestamp]
			promptcloud_api_url += "&ts=#{args_hash[:timestamp]}"
			File.open(args_hash[:queried_timestamp_file], "w") do |file|
				file << args_hash[:timestamp]
			end
		end
		promptcloud_api_url += "&days=#{args_hash[:days]}" if args_hash[:days]
		promptcloud_api_url += "&hours=#{args_hash[:hours]}" if args_hash[:hours]
		promptcloud_api_url += "&minutes=#{args_hash[:minutes]}" if args_hash[:minutes]
		promptcloud_api_url += "&cat=#{args_hash[:category]}" if args_hash[:category]
		promptcloud_api_url += "&site=#{args_hash[:site]}" if args_hash[:site]
		return promptcloud_api_url
	end

	def handle_api_downtime(args_hash)
		if @api_downtime
			total_downtime = Time.now - @api_downtime
			if total_downtime > 1800
				args_hash[:bcp] = true
			end
		else
			@api_downtime = Time.now
		end
	end

	def disable_bcp(args_hash)
		if args_hash[:bcp]
			args_hash[:bcp] = nil
			@api_downtime = nil
		end
	end

	def get_file_urls(args_hash)
		ts_urls_map = {}
		url_md5_map = {}
		begin
			promptcloud_api_url = get_api_url(args_hash)
			$stdout.puts "Getting files to download from #{promptcloud_api_url}"
			api_query_output = ""
			RestClient.get(promptcloud_api_url) do |response, request, result, &block|
				if [301, 302, 307].include? response.code
					response.follow_redirection(request, result, &block)
				else
					response.return!(request, result, &block)
				end
				if response.code != 200
					if args_hash[:bcp]
						$stderr.puts "Sorry, our bcp server is also down, please mail to downtime@promptcloud.com"
						disable_bcp(args_hash)
					else
						if args_hash[:loop]
							$stderr.puts "Could not fetch from PromptCloud data api server, will try the api server after the sleep and bcp server after 30 mins"
						else
							$stderr.puts "Main api server seems to be unreachable, you can try --bcp option"
						end
						handle_api_downtime(args_hash)
					end
				else
					api_query_output = response
					disable_bcp(args_hash) #next fetch will be from promtcloud api
				end
			end
			doc = REXML::Document.new(api_query_output) if api_query_output
			unless doc
				$stderr.puts "Could not create xml doc"
				return nil,nil
			end
			REXML::XPath.each(doc, '//entry').each do |entry_node|
				updated_node = REXML::XPath.first(entry_node, './updated')
				updated = updated_node.text.chomp.strip.to_i
				url_node = REXML::XPath.first(entry_node, './url')
				url = url_node.text.chomp.strip
				md5_node = REXML::XPath.first(entry_node, './md5sum')
				md5sum = md5_node.text.chomp.strip
				url_md5_map[url] = md5sum
				if ts_urls_map[updated]
					ts_urls_map[updated].push(url)
				else
					ts_urls_map[updated]=[url]
				end
			end
			#REXML::XPath.each(doc, '//url').each{|node| urls.push(node.text)}
		rescue Exception=>e
			$stderr.puts "#{$@} : Api query failed:#{e.class}, #{e.message}"
			return nil, nil
		end
		return ts_urls_map, url_md5_map
	end
end

class PromptCloudTimer
	def initialize(args_hash={})
		super()
		if args_hash[:min]
			@min=args_hash[:min]
		else
			@min=10
		end

		if args_hash[:max]
			@max=args_hash[:max]
		else
			@max=300
		end
		@sleep_interval=@min
	end

	def wait
		$stderr.puts "Going to sleep for #{@sleep_interval} seconds"
		sleep(@sleep_interval)
		@sleep_interval *=2 
		if @sleep_interval > 300
			@sleep_interval=10
		end
	end
end

class PromptCloudApiArgParser
	
	def initialize()
		super
	end

	def self.validate(options,mandatory)
		options[:api_version] = "v1" if not options[:api_version] # default version
		options[:api_version] = options[:api_version].downcase
		if not ["v1","v2"].include? options[:api_version]
			$stderr.puts "#{options[:api_version]} is not a valid api version. Please pass v1 or v2.(v1 is the default)"
			return false
		end
		return true
	end

	def self.usage_notes
		script_name=$0
		$stderr.puts <<END
Example :
END
	end
		

	def self.parse(args,defaults={},mandatory=[])
		options= {}
		options= options.merge(defaults)
		opts=OptionParser.new do |opts|
			opts.banner = "Usage: #{$0} [options] "
			
			opts.on("-v","--api_version VERSION",String, "to get data from different api version(available versions are v1 and v2, the defalut version is v1)") do |v|
				options[:api_version] = v
			end

			opts.on("-u","--user USER",String, "data api user id(provided by PromptCloud)") do |v|
				options[:user] = v
			end

			opts.on("-p","--pass PASSWORD",String, "data api password(provised by PromptCloud, used for api v1)") do |v|
				options[:pass] = v
			end

			opts.on("-k","--client_auth_key AUTHKEY",String, "data api client auth key(provided by PromptCloud, used for api v2)") do |v|
				options[:client_auth_key] = v
			end
			
			opts.on("-i","--perform_initial_setup", "to perform initial setup") do |v|
				options[:perform_initial_setup] = v
			end
			
			opts.on("--display_info", "to display config info") do |v|
				options[:display_info] = v
			end

			opts.on("--apiconf APICONFPATH",String, "to override the config file path(config file stores information like client_id, password, client_auth_key, downloadir etc)") do |v|
				options[:apiconf] = v
			end

			opts.on("--download_dir DOWNLOAD_DIRECTORY",String, "to override the download dir(which contains downloaded data files)") do |v|
				options[:download_dir] = v
			end

			opts.on("--promptcloudhome PROMPTCLOUDHOME",String, "to override the promptcloudhome dir(~/promptcloud)") do |v|
				options[:promptcloudhome] = v
			end

			opts.on("-t","--timestamp TIMESTAMP",Integer, "to query promptcloud api for files newer than or equal to given timestamp") do |v|
				options[:timestamp] = v
			end
			
			opts.on("--days DAYS",Integer, "to download the data of last few days") do |v|
				options[:days] = v
			end
			
			opts.on("--hours DAYS",Integer, "to download the data of last few hours") do |v|
				options[:hours] = v
			end
			
			opts.on("--minutes MINUTES",Integer, "to download the data last few minutes") do |v|
				options[:minutes] = v
			end
			
			opts.on("--queried_timestamp_file queried TIMESTAMPFILE",String, "to override the last timestamp file(contains last queried timestamp)") do |v|
				options[:queried_timestamp_file] = v
			end

			opts.on("--category CATEGORY ",String, "to query promptcloud api for files of the given category(if files of different verticals are placed in different directory under client's parent directory, then files of specific directory can be obtained by specifying that directory name in category option)") do |v|
				options[:category] = v
			end
			
			opts.on("--site SITE_NAME",String, "to query promptcloud api for files of the given site") do |v|
				options[:site] = v
			end
			
			opts.on("--loop", "download new data files and keep looking for new one(i.e it doesn't exit, if no new feed is found it will sleep, minimun sleep time is 10 secs and max sleep time is 300 secs)") do |v|
				options[:loop] = v
			end

			opts.on("--noloop", "download new data files and and exit, this is the default behaviour") do |v|
				options[:noloop] = v
			end

			opts.on("--bcp", "to download data from PromptCloud backup server(high availability server, should use if main data api server is unreachable)") do |v|
				options[:bcp] = v
			end
			
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				usage_notes
				exit(-1)
			end
		end

		opts.parse!(args)
		if validate(options,mandatory)
			return options
		else
			$stderr.puts "#{$@} Invalid/no args, see use -h command for help"
			exit(-1)
		end
	end
end
