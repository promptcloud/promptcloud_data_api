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
	def initialize(args_hash={})
		super()
		
		@download_dir=nil
		@client_id=nil
		perform_initial_setup(args_hash)
	end

	def display_info(options)
		apiconf="#{@@promptcloudhome}/configs/config.yml"
		if options[:apiconf]
			apiconf = options[:apiconf]
		end

		if File.file?(apiconf)
			conf_hash=YAML::load_file(apiconf)
			conf_hash.each_pair do |key, val|
				puts "#{key} : #{val}"
			end
		else
			$stderr.puts "Config file #{apiconf} doesn't exist"
		end
	end
	#optional argument options={:promptcloudhome=>..., :apiconf=>...., :queried_timestamp_file=>}
	def perform_initial_setup(options={})
		if options[:promptcloudhome]
			@@promptcloudhome=options[:promptcloudhome]
		end

		if not File.directory?(@@promptcloudhome)
			FileUtils.mkdir_p(@@promptcloudhome)
		end

		unless options[:apiconf]
			options[:apiconf]="#{@@promptcloudhome}/configs/config.yml"
		end
		if not File.directory?(File.dirname(options[:apiconf]))
			FileUtils.mkdir_p(File.dirname(options[:apiconf]))
		end

		if not  File.file?(options[:apiconf])
			$stderr.puts "#{$@} : Could not find config file : #{options[:apiconf]}"
			$stderr.puts "Please input your id( for example if you use url http://api.promptcloud.com/data/info?id=demo then your user id is demo
			)"
			client_id=STDIN.gets.chomp.strip
			yml_val={"client_id" => client_id, "download_dir" => File.join(@@promptcloudhome, "downloads")}
			File.open(options[:apiconf], "w") do |file|
				file << yml_val.to_yaml
			end
		end

		unless options[:log_dir]
			options[:log_dir]="#{@@promptcloudhome}/log"
		end
		if not File.directory?(options[:log_dir])
			FileUtils.mkdir_p(options[:log_dir])
		end

		unless options[:md5_dir]
			options[:md5_dir]="#{@@promptcloudhome}/md5sums"
		end
		if not File.directory?(options[:md5_dir])
			FileUtils.mkdir_p(options[:md5_dir])
		end

		unless options[:queried_timestamp_file]
			options[:queried_timestamp_file]="#{@@promptcloudhome}/last_queried_ts"
		end

		@conf_hash=YAML::load_file(options[:apiconf])
		@client_id=@conf_hash["client_id"]

		unless @client_id
			$stderr.puts "#{$@} : Could not find client id from config file : #{options[:apiconf]}"
			exit 1
		end

		@download_dir=@conf_hash["download_dir"]
		unless @download_dir
			@download_dir=File.join(@@promptcloudhome, "downloads")
		end

		if not File.directory?(@download_dir)
			FileUtils.mkdir_p(@download_dir)
		end
	end

	def download_files(options)
		if not options[:user] or not options[:pass]
			raise Exception.new("You didn't provide username and password, please provide these as hash:{:user=><userid>, :pass=><password>}")
		end
		new_feed_exists=false
		ts=("%10.9f" % (Time.now).to_f).to_s.gsub(/\./, "").to_i
		fetch_log="#{options[:log_dir]}/fetched_urls-#{ts}.log"
		fetch_log_file=File.open(fetch_log, "w")
		urls_ts_map, url_md5_map=get_file_urls(options)
		if not urls_ts_map
			$stderr.puts "#{$@} : Could not obtain file urls to download."
			new_feed_exists
		end
		if urls_ts_map.keys.empty?
			$stderr.puts "No new files to download"
			return new_feed_exists
		end

		sorted_ts=urls_ts_map.keys.sort
		sorted_ts.each do |ts|
			urls=urls_ts_map[ts]
			urls.each do |url|
				md5sum=url_md5_map[url]
				filename=File.basename(url)
				md5_filename=filename.gsub(/\.gz/, ".md5sum")
				md5_filepath=options[:md5_dir]+ "/#{md5_filename}"
				if File.file?(md5_filepath) and File.open(md5_filepath).read.chomp.strip==md5sum
					$stderr.puts "Skipping file at url : #{url}, it has been downloaded earlier"
					next
				end
				new_feed_exists=true

				begin
					$stderr.puts "Fetching : #{url}"
					req=RestClient::Request.new({:method=>"get",:user=>options[:user], :password =>options[:pass], :url =>url})
					outfile=File.join(@download_dir, File.basename(url))
					File.open(outfile, "wb") do |file|
						file.write req.execute
						fetch_log_file << "Fetched: #{url}"
					end
					content=""
					Zlib::GzipReader.open(outfile) {|gz|
						content = gz.read
					}
					downloaded_md5 = Digest::MD5.hexdigest(content)
					if md5sum==downloaded_md5
						File.open(md5_filepath, "w"){|file| file.puts md5sum}
					else
						$stderr.puts "Url : #{url} was not downloaded completely, hence deleting the downloaded file"
						File.delete(outfile)
					end
				rescue Exception => e
					$stderr.puts "#{$@} : Failed to fetch url : #{url}"
					fetch_log_file.puts "#{$@} #{e.class}, #{e.message}"
					fetch_log_file.puts "Failed: #{url}"
				end
			end
		end
		
		fetch_log_file.close
		$stderr.puts "Log file : #{fetch_log}"
		$stderr.puts "Downloaded files are available at:#{@download_dir}"
		return new_feed_exists
	end

	private
	def get_api_url(options)
		promptcloud_api_query="https://api.promptcloud.com/data/info?id=#{@client_id}"
		if options[:bcp]
			promptcloud_api_query="https://api.bcp.promptcloud.com/data/info?id=#{@client_id}"
		end

		if options[:timestamp]
			promptcloud_api_query+="&ts=#{options[:timestamp]}"
			File.open(options[:queried_timestamp_file], "a") do |file|
				file << options[:timestamp]
			end
		end

		if options[:category]
			promptcloud_api_query+="&cat=#{options[:category]}"
		end
		return promptcloud_api_query
	end

	def handle_api_downtime(options)
		if @api_downtime
			total_downtime=Time.now - @api_downtime
			if total_downtime > 1800
				options[:bcp]=true
			end
		else
			@api_downtime=Time.now
		end
	end

	def disable_bcp(options)
		if options[:bcp]
			options[:bcp]=nil
			@api_downtime=nil
		end
	end

	def get_file_urls(options)
		url_ts_map={}
		url_md5_map={}
		begin
			promptcloud_api_query=get_api_url(options)
			api_query_output=""
			RestClient.get(promptcloud_api_query) do |response, request, result, &block|
				if [301, 302, 307].include? response.code
					response.follow_redirection(request, result, &block)
				else
					response.return!(request, result, &block)
				end
  				puts "res code: #{response.code}"
				if response.code!=200
					if options[:bcp]
						$stderr.puts "bcp too is down :(, please mail downtime@promptcloud.com "
						disable_bcp(options)
					else
						if options[:loop]
							$stderr.puts "Could not fetch from promptcloud api server, will try after the api server after the sleep and  promptcloud bcp after 30 mins"
						else
							$stderr.puts "Main api server seems to be unreachable, you can try --bcp option"
						end
						handle_api_downtime(options)
					end
				else
					api_query_output=response
					disable_bcp(options) #next fetch will be from promtcloud api
				end
			end
			api_query_output=open(promptcloud_api_query)
			doc=REXML::Document.new(api_query_output)
			REXML::XPath.each(doc, '//entry').each do |entry_node|
				updated_node=REXML::XPath.first(entry_node, './updated')
				updated=updated_node.text.chomp.strip.to_i
				url_node=REXML::XPath.first(entry_node, './url')
				url=url_node.text.chomp.strip
				md5_node=REXML::XPath.first(entry_node, './md5sum')
				md5sum=md5_node.text.chomp.strip
				url_md5_map[url]=md5sum
				if url_ts_map[updated]
					url_ts_map[updated].push(url)
				else
					url_ts_map[updated]=[url]
				end
			end
			#REXML::XPath.each(doc, '//url').each{|node| urls.push(node.text)}
		rescue Exception=>e
			$stderr.puts "#{$@} : Api query failed:#{e.class}, #{e.message}"
			return nil, nil
		end
		return url_ts_map, url_md5_map
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
		if not options[:perform_initial_setup] and not options[:display_info] and (not options[:user] or not options[:pass])
			$stderr.puts "#{$@} : Please provide options perform_initial_setup/display_info or provide user and password for any other query"
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


			opts.on("--apiconf APICONFPATH",String, "override the config file location, the file which stores information like client_id, downloadir, previous timestamp file") do |v|
				options[:apiconf] = v
			end

			opts.on("--download_dir DOWNLOADDIR",String, "to override the download dir obtained from apiconf file") do |v|
				options[:download_dir] = v
			end

			opts.on("--promptcloudhome PROMPTCLOUDHOME",String, "to override the promptcloudhome dir:~/promptcloud") do |v|
				options[:promptcloudhome] = v
			end

			opts.on("--perform_initial_setup", "Perform initial setup") do |v|
				options[:perform_initial_setup] = v
			end
			opts.on("--display_info", "Display veraiou info ") do |v|
				options[:display_info] = v
			end

			opts.on("--timestamp TIMESTAMP",Integer, "query promptcloudapi for files newer than or equal to given timestamp") do |v|
				options[:timestamp] = v
			end

			opts.on("--queried_timestamp_file queriedTIMESTAMPFILE",String, "override default queried_timestamp_file: file that stores last queried timestamp") do |v|
				options[:queried_timestamp_file] = v
			end

			opts.on("--category CATEGORY ",String, "query promptcloudapi for files of given category. eg: if files of different verticals are placed in different directory under client's parent directory, then files of specific directory can be obtained by specifying that directory name in category option") do |v|
				options[:category] = v
			end

			opts.on("--user USER",String, "Data api user id") do |v|
				options[:user] = v
			end

			opts.on("--pass PASSWORD",String, "Data api password") do |v|
				options[:pass] = v
			end

			opts.on("--loop", "download new data files and keep looking for new one. i.e it doesn't exit, if no new feed is found it will sleep. minimun sleep time is 10 secs and max sleep time is 300 secs") do |v|
				options[:loop] = v
			end

			opts.on("--noloop", "Download new data files and and exit, this is the default behaviour") do |v|
				options[:noloop] = v
			end

			opts.on("--bcp", "use bcp.promptcloud.com instead of api.promptcloud.com") do |v|
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
