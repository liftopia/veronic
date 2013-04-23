require_relative 'config/config'
require_relative 'providers/cloudprovider'
require_relative 'providers/dnsprovider'
require_relative 'providers/configprovider'
require 'pp'

module Veronic
	class Deployer

		def initialize(options={})
			@config = config(options)
		end
		
		def config
			@config || Veronic::Config.new
		end

		def config(options={})
			@config || Veronic::Config.new(options)
		end

		def config_hash
			@config.to_hash
		end		

		def configprovider
			ConfigProvider.new(config_hash) 
		end

		def dnsprovider
			DnsProvider.new(config_hash)
		end

		def cloudprovider
			CloudProvider.new(config_hash)
		end

		def create
			unless bootstrap
				configprovider.instance.create
			end
		end

		def deploy_stacks
			bootstrap
			query = cloudprovider.instance.dns_name
			deploy_cmd = 'sudo chef-client -l debug'
			manual = true
			configprovider.ssh(query, deploy_cmd, manual)
		end

		def deploy_apps
			if bootstrap
				deploy_stacks
			end
			query = cloudprovider.instance.dns_name
			deploy_cmd = "sudo chef-client -o 'recipe[lift_envs::app_deploy]' #{@config.verbose ? '-l ' + @config.verbose : ''}"
			manual = true
			configprovider.ssh(query, deploy_cmd, manual)
		end

		def run_tests
			if bootstrap
				deploy_stacks
				deploy_apps
			end
			query = cloudprovider.instance.dns_name
			deploy_cmd = "sudo chef-client -o 'recipe[lift_envs::app_testing]' #{@config.verbose ? '-l ' + @config.verbose : ''}"
			manual = true
			configprovider.ssh(query, deploy_cmd, manual)
		end

		def destroy
			@config.dnsprovider_zones.each do |z|
				@config.zone_name 	= z['zone_name']
				@config.zone_url 	= z['zone_url']
				dns 				= "#{@config.name}.#{z['zone_name']}"
				puts 				"Setting DNS #{dns} ..."
				record 				= dnsprovider.zone.record(dns, [], "A", "1").delete
				puts 				"DNS #{dns} deleted"
			end
			if cloudprovider.instance.exist?
				configprovider.instance.destroy([cloudprovider.instance.id])
			else
				configprovider.instance.destroy([])
			end

		end

		def deploy
			if cloudprovider.instance.exist?
				if @environment == 'branch'
					query = cloudprovider.instance.dns_name
					manual = true
				else
					query = "role:#{@role}"
					manual = false
				end
				configprovider.ssh(query, @deploy_cmd, manual)
			end
		end

		def update_instance_dns
			@config.dnsprovider_zones.each do |z|
				@config.zone_name 	= z['zone_name']
				@config.zone_url 	= z['zone_url']
				dns 				= "#{@config.name}.#{z['zone_name']}"
				puts 				"Setting DNS #{dns} ..."
				record 				= dnsprovider.zone.record(dns, [cloudprovider.instance.public_ip_address], "A", "1").wait_set
				puts 				"DNS #{dns} updated"
			end
		end

		def instances_list
			cloudprovider.instances_list
		end

		def stop
			cloudprovider.instance.stop
		end

		def start
			unless cloudprovider.instance.start == false
				update_instance_dns
			end
		end

		def status
			if @config.name
				return cloudprovider.instance.status
			else
				return "Arguments name missing"
			end
		end

		def bootstrap
			status = false
			if cloudprovider.instance.status == :running
				puts "#{@config.name} is running"	
			elsif cloudprovider.instance.status == :stopped
				start
			elsif cloudprovider.instance.exist? == false
				get_image
				configprovider.instance.bootstrap 
				update_instance_dns
				status = true
			else
				abort('Error during connecting instance')  
			end
			set_node
			return status
		end

		def create_image
			unless @config.environment
				abort('Arguments "environment" missing') 
			else
				configprovider.instance.client.destroy
				configprovider.instance.delete_client_key(cloudprovider.instance.dns_name)
				cloudprovider.image.detroy
				cloudprovider.instance.create_image
			end
		end

		def set_node
			if @config.role && @config.environment
				configprovider.instance.set_environment
				configprovider.instance.set_role
			else
				abort('Arguments "role" or "environment" missing') 
			end
		end

		def get_image
			if @config.image.nil?
				unless @config.environment
					abort('Arguments "environment" missing') 
				else
					@config.image = cloudprovider.image.id
				end
			else
				@config.image = cloudprovider.image(@config.image).id
			end
		end
	end
end
