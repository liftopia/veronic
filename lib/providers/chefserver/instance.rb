require 'chef/knife'
require 'chef/knife/ec2_server_create'
require 'chef/knife/ec2_server_delete'
require 'chef/knife/bootstrap'
require 'chef/knife/ssh'
require 'chef/knife/node_run_list_add'
require 'chef/knife/core/bootstrap_context'
require 'chef/knife/ec2_base'
require 'chef/node'

require_relative 'rest_request'

module Provider
	class ChefServer
		class Instance

			def initialize(config)
				@access_key_id									= config[:cloudprovider_access_key_id]
				@secret_access_key								= config[:cloudprovider_secret_access_key]
				@name											= config[:name]
				@image 											= config[:image]
				@security_groups								= config[:security_groups]
				@ssh_user										= config[:ssh_user]
				@ssh_port										= config[:ssh_port]
				@identity_file									= config[:identity_file]
				@aws_ssh_key_id									= config[:aws_ssh_key_id]
				@environment									= config[:environment]
				@roles											= "role[#{config[:role]}]"
				@flavor											= config[:flavor]
				@region											= config[:region]
				@availability_zone								= config[:availability_zone]
				Chef::Config[:knife][:image] 					= @image
				Chef::Config[:knife][:aws_ssh_key_id] 			= @aws_ssh_key_id
				Chef::Config[:knife][:aws_access_key_id] 		= @access_key_id
				Chef::Config[:knife][:aws_secret_access_key] 	= @secret_access_key
				Chef::Config[:knife][:region]					= @region
				Chef::Config[:knife][:availability_zone]		= @availability_zone
				Chef::Config[:knife][:log_level] 				= :debug
			end

			def create
				puts "Creating ec2 server #{@name} ..."
				
				create = Chef::Knife::Ec2ServerCreate.new()

				create.config[:run_list]        	= [@roles]
				create.config[:image]           	= @image
				create.config[:flavor]          	= @flavor
				create.config[:security_groups] 	= @security_groups
				create.config[:ssh_user]        	= @ssh_user
				create.config[:ssh_port]        	= @ssh_port
				create.config[:chef_node_name]  	= @name
				create.config[:identity_file]		= @identity_file
				create.config[:environment]			= @environment
				create.config[:log_level] 			= :debug

				puts create.config
				create.run
			end

			def bootstrap
				puts "Bootstrapping ec2 server #{@name} ..."
				
				bootstrap = Chef::Knife::Ec2ServerCreate.new()

				bootstrap.config[:image]           	= @image
				bootstrap.config[:flavor]          	= @flavor
				bootstrap.config[:security_groups] 	= @security_groups
				bootstrap.config[:ssh_user]        	= @ssh_user
				bootstrap.config[:ssh_port]        	= @ssh_port
				bootstrap.config[:chef_node_name]  	= @name
				bootstrap.config[:identity_file]	= @identity_file
				bootstrap.config[:environment]		= @environment
				bootstrap.config[:log_level] 		= :debug

				puts bootstrap.config
				bootstrap.run
			end

			def destroy(instance_ids = [])
				puts "Deleting ec2 server #{@name} ..."

				destroy = Chef::Knife::Ec2ServerDelete.new()

				destroy.config[:purge]        		= true
				destroy.config[:chef_node_name]		= @name
				destroy.config[:yes]				= true
				destroy.name_args 					= instance_ids

				puts destroy.config
				destroy.run
				destroy.destroy_item(Chef::Node, @name, "node")
				destroy.destroy_item(Chef::ApiClient, @name, "client")
			end

			def set_role
				node = Chef::Knife::NodeRunListAdd.new()
				node.name_args = [@name, @roles]
				node.run
			end

			def set_environment
				node = Chef::Node.new.tap do |n|
					n.name( @name )
          			n.chef_environment( @environment )
          		end
          		node.save
          		puts "Environment: #{@environment}"
			end

			def ssh(query, cmd_line, manual)
				knife_ssh = Chef::Knife::Ssh.new()

				knife_ssh.config[:manual] 			= manual
				knife_ssh.config[:ssh_user] 		= @ssh_user
				knife_ssh.config[:identity_file] 	= @identity_file
				knife_ssh.config[:log_level] 		= :debug

				knife_ssh.name_args = [query, cmd_line]
				sys_status =  knife_ssh.run
			end

		end
	end
end