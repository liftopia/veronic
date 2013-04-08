require 'fog'
require 'chef'
require 'chef/json_compat'
require 'chef/node'
require 'chef/api_client'
require 'tempfile'
require 'highline'
require 'net/ssh'
require 'net/ssh/multi'
require_relative 'instance'

module Provider
	class ChefServer

		def initialize(config)
			@path 									= File.dirname($0)
			@config 								= config
			Chef::Config[:environment] 				= config[:environment]
			Chef::Config[:node_name] 				= config[:node_name]
			Chef::Config[:client_key] 				= config[:client_key]
			Chef::Config[:validation_client_name] 	= config[:validation_client_name]
			Chef::Config[:validation_key] 			= config[:validation_key]
			Chef::Config[:chef_server_url] 			= config[:chef_server_url]
			Chef::Config[:ssl_version]				= config[:ssl_version]
			Chef::Config[:log_level] 				= :debug
			@knife = knife
		end

		def knife
			knife = Provider::ChefServer::Instance.new(@config)	
		end

		def instances(query)
			q = Chef::Search::Query.new
			nodes = q.search(:node, query).first
			nodes
		end

		def search(query)
			q = Chef::Search::Query.new
			nodes = q.search(:node, query).first
			nodes
		end

		def ssh(query, deploy_cmd, manual)
			@knife.ssh(query, deploy_cmd, manual)
		end

		def instance
			instance = Provider::ChefServer::Instance.new(@config)
		end
		
	end
end
