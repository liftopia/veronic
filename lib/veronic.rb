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
			deploy_cmd = 'sudo chef-client -o "recipe[lift_envs::app_deploy]" -l debug'
			manual = true
			configprovider.ssh(query, deploy_cmd, manual)
		end

		def run_tests
			if bootstrap
				deploy_stacks
				deploy_apps
			end
			query = cloudprovider.instance.dns_name
			deploy_cmd = 'sudo chef-client -o "recipe[lift_envs::app_testing]" -l debug'
			manual = true
			configprovider.ssh(query, deploy_cmd, manual)
		end

		def destroy
			config_hash[:dnsprovider_zones].each do |z|
				@config.zone_name 	= z['zone_name']
				@config.zone_url 	= z['zone_url']
				dns 				= "#{config_hash[:name]}.#{z['zone_name']}"
				puts 				"Setting DNS #{dns} ..."
				record 				= dnsprovider.zone.record(dns, [cloudprovider.instance.public_ip_address], "A", "10").delete
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
			config_hash[:dnsprovider_zones].each do |z|
				@config.zone_name 	= z['zone_name']
				@config.zone_url 	= z['zone_url']
				dns 				= "#{config_hash[:name]}.#{z['zone_name']}"
				puts 				"Setting DNS #{dns} ..."
				record 				= dnsprovider.zone.record(dns, [cloudprovider.instance.public_ip_address], "A", "10").wait_set
				puts 				"DNS #{dns} updated"
			end
		end

		def instances_list
			cloudprovider.instances_list
		end

		def stop
			if cloudprovider.instance.exist?
				cloudprovider.instance.stop
			end
		end

		def start
			if cloudprovider.instance.exist?
				cloudprovider.instance.start
				update_instance_dns
			end
		end

		def bootstrap
			@config.image = cloudprovider.image.id
			if cloudprovider.instance.status == :running
				puts "#{config_hash[:name]} is running"		
			elsif cloudprovider.instance.status == :stopped
				start
			elsif cloudprovider.instance.exist? == false
				configprovider.instance.bootstrap 
				configprovider.instance.set_environnment
				configprovider.instance.set_role
				update_instance_dns
				return true
			else
				raise ArgumentError.new('Error during connecting instance')  
			end
			configprovider.instance.set_environnment
			configprovider.instance.set_role
			return false
		end
	end
end
