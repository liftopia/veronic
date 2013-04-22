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
				@verbose 										= config[:verbose]
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
				
				node = Chef::Knife::Ec2ServerCreate.new()

				node.config[:run_list]        	= [@roles]
				node.config[:image]           	= @image
				node.config[:flavor]          	= @flavor
				node.config[:security_groups] 	= @security_groups
				node.config[:ssh_user]        	= @ssh_user
				node.config[:ssh_port]        	= @ssh_port
				node.config[:chef_node_name]  	= @name
				node.config[:identity_file]		= @identity_file
				node.config[:environment]		= @environment
				node.config[:log_level] 		= @verbose

				puts node.config
				node.run
			end

			def bootstrap(recursive_count=0)
				puts "Bootstrapping ec2 server #{@name} ..."
				
				node = Chef::Knife::Ec2ServerCreate.new()

				node.config[:image]           	= @image
				node.config[:flavor]          	= @flavor
				node.config[:security_groups] 	= @security_groups
				node.config[:ssh_user]        	= @ssh_user
				node.config[:ssh_port]        	= @ssh_port
				node.config[:chef_node_name]  	= @name
				node.config[:identity_file]		= @identity_file
				node.config[:environment]		= @environment
				node.config[:log_level] 		= @verbose

				puts node.config
				begin
					node.run
				rescue
					self.destroy([node.server.id])
					self.bootstrap(recursive_count+=1) if recursive_count < 3
				end
			end

			def destroy(instance_ids = [])
				puts "Deleting ec2 server #{@name} ..."

				node = Chef::Knife::Ec2ServerDelete.new()

				node.config[:purge]        		= true
				node.config[:chef_node_name]	= @name
				node.config[:yes]				= true
				node.name_args 					= instance_ids

				puts node.config
				node.run
				node.destroy_item(Chef::Node, @name, "node")
				node.destroy_item(Chef::ApiClient, @name, "client")
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
				knife_ssh.config[:log_level] 		= @verbose

				knife_ssh.name_args = [query, cmd_line]
				sys_status =  knife_ssh.run
			end

		end
	end
end