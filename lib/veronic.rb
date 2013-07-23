require_relative 'config/config'
require_relative 'providers/cloudprovider'
require_relative 'providers/dnsprovider'
require_relative 'providers/configprovider'
require 'pp'

module Veronic
	class Deployer

		def initialize(options={})
			@config = config(options)
			@logger = logger("stderr")
		end
		
		def config
			@config || Veronic::Config.new
		end

		def logger(options={})
			Veronic::Logger.new(options)
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
			deploy_cmd = "sudo chef-client #{@config.verbose ? '-l ' + @config.verbose : ''}"
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
				@logger.message 				"Setting DNS #{dns} ..."
				record 				= dnsprovider.zone.record(dns, [], "A", "1").delete
				@logger.message 				"DNS #{dns} deleted"
			end
			if cloudprovider.instance.exists?
				configprovider.instance.destroy([cloudprovider.instance.id])
			else
				configprovider.instance.destroy([])
			end

		end

		def deploy
			unless @config.deploy_cmd
				abort('Arguments --deploy_cmd is missing')
			end 
			bootstrap
			query = cloudprovider.instance.dns_name
			manual = true
			configprovider.ssh(query, @config.deploy_cmd, manual)
		end

		def search_and_deploy
			unless @config.deploy_cmd || @config.query
				abort('Arguments --deploy_cmd or --query is missing')
			end 
			query = @config.query
			manual = false
			configprovider.ssh(query, @config.deploy_cmd, manual)
		end

		def update_instance_dns
			if @config.dnsprovider_zones
  			@config.dnsprovider_zones.each do |z|
  				@config.zone_name 	= z['zone_name']
  				@config.zone_url 	= z['zone_url']
  				dns 				= "#{@config.name}.#{z['zone_name']}"
  				@logger.message 				"Setting DNS #{dns} ..."
  				record 				= dnsprovider.zone.record(dns, [cloudprovider.instance.dns_name], "CNAME", "1").wait_set
  				@logger.message 				"DNS #{dns} updated"
        end
      else
        @logger.message "Unabled to update DNS"
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
				exit 1
			end
		end

		def status
			if @config.name
				return cloudprovider.instance.status
			else
				return "Arguments --name is missing"
			end
		end

		def bootstrap
			status = false
			if cloudprovider.instance.status == :running
				@logger.message "#{@config.name} is running"	
			elsif cloudprovider.instance.status == :stopped
				start
			elsif cloudprovider.instance.exists? == false
				@config.availability_zone = get_availability_zone
				get_image
				configprovider.instance.client.destroy
				configprovider.instance.bootstrap 
				status = true
			else
				abort('Error during connecting instance')  
			end
			set_node
			return status
		end

		def create_image
			configprovider.instance.delete_client_key(cloudprovider.instance.dns_name)
			configprovider.instance.client.destroy
			cloudprovider.image.detroy
			cloudprovider.instance.create_image
		end

		def set_node
			update_instance_dns
			if @config.role && @config.environment
				configprovider.instance.set_environment
				configprovider.instance.set_role
				cloudprovider.instance.tags({'role' => @config.role, 'environment' => @config.environment})
				if configprovider.instance.delete_client_key(cloudprovider.instance.dns_name)
					configprovider.instance.client.destroy
				end
			else
				@logger.message 'Unable to set_node arguments --role or --environment is missing'
			end
		end

		def get_image
			if @config.image.nil?
				abort('Arguments --ami_image is missing') 
			else
				@config.image = cloudprovider.image.id
			end
		end

		def get_availability_zone
			@logger.message "Getting availability zone ..."
			environments = {}
			if @config.availability_zone.nil? || @config.availability_zone == 'auto'
				cloudprovider.regions.each do |region|
					region.instances.each do |instance|
						if instance.tags[:environment] && instance.tags[:role] && instance.status != :shutting_down && instance.status != :terminated
							environments[instance.tags[:environment]] = {} unless environments[instance.tags[:environment]]
							environments[instance.tags[:environment]][instance.tags[:role]] = {} unless environments[instance.tags[:environment]][instance.tags[:role]]
							environments[instance.tags[:environment]][instance.tags[:role]][region.name] = {} unless environments[instance.tags[:environment]][instance.tags[:role]][region.name]
							region.availability_zones.each do |availability_zone|
								environments[instance.tags[:environment]][instance.tags[:role]][region.name][availability_zone.name] = [] unless environments[instance.tags[:environment]][instance.tags[:role]][region.name][availability_zone.name]
							end
							environments[instance.tags[:environment]][instance.tags[:role]][region.name][instance.availability_zone] << instance.id
						end
					end
				end
			end
			if environments[@config.environment] && environments[@config.environment][@config.role] && environments[@config.environment][@config.role][@config.region]
				availability_zones = environments[@config.environment][@config.role][@config.region].sort_by { |availability_zone| availability_zone[1].count }
				@logger.message "Zones: " + availability_zones.to_s
				availability_zone = availability_zones.first
				@logger.message "Zone selected: " + availability_zone[0]
				availability_zone[0]
			end
		end
	end
end
