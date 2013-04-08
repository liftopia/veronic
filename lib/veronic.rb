require_relative 'providers/cloudprovider'
require_relative 'providers/dnsprovider'
require_relative 'providers/configprovider'

module Veronic
	class Deployer

		def initialize(config)
			@role			= config[:role]
			@environment	= config[:environment]	
			@deploy_cmd		= config[:deploy_cmd]
			@dns_array 		= config[:dns_array] 
			@cloudprovider 	= CloudProvider.new(config)
			config[:image]	= @cloudprovider.image.id
			@dnsprovider 	= DnsProvider.new(config)
			@configprovider = ConfigProvider.new(config)
		end

		def create
			if bootstrap
				@configprovider.instance.create
			end
		end

		def deploy_stacks
			bootstrap
			query = @cloudprovider.instance.dns_name
			deploy_cmd = 'sudo chef-client -l debug'
			manual = true
			@configprovider.ssh(query, deploy_cmd, manual)
		end

		def deploy_apps
			unless bootstrap
				deploy_stacks
			end
			query = @cloudprovider.instance.dns_name
			deploy_cmd = 'sudo chef-client -o "recipe[lift_envs::app_deploy]" -l debug'
			manual = true
			@configprovider.ssh(query, deploy_cmd, manual)
		end

		def run_tests
			unless bootstrap
				deploy_stacks
				deploy_apps
			end
			query = @cloudprovider.instance.dns_name
			deploy_cmd = 'sudo chef-client -o "recipe[lift_envs::app_testing]" -l debug'
			manual = true
			@configprovider.ssh(query, deploy_cmd, manual)
		end

		def destroy
			if @cloudprovider.instance.exist?
				@configprovider.instance.destroy([@cloudprovider.instance.id])
			else
				@configprovider.instance.destroy([])
			end
		end

		def deploy
			if @cloudprovider.instance.exist?
				if @environment == 'branch'
					query = @cloudprovider.instance.dns_name
					manual = true
				else
					query = "role:#{@role}"
					manual = false
				end
				@configprovider.ssh(query, @deploy_cmd, manual)
			end
		end

		def update_instance_dns
			@dns_array.each do |dns|
				puts "Setting DNS #{dns} ..."
			    @dnsprovider.zone.record.new(@dnsprovider.zone, dns, [@cloudprovider.instance.public_ip_address], "A", "10")
			    puts "DNS #{dns} updated"
			end
		end

		def instances_list
			@cloudprovider.instances_list
		end

		def stop
			@cloudprovider.instance.stop
		end

		def start
			@cloudprovider.instance.start
			update_instance_dns
		end

		def bootstrap		
			if @cloudprovider.instance.status == :running
				return true
			elsif @cloudprovider.instance.status == :stopped
				start
				return true
			elsif @cloudprovider.instance.exist? == false
				@configprovider.instance.bootstrap
				@configprovider.instance.set_role
				return false
			else
				raise ArgumentError.new('Error during connecting instance')  
			end
		end
	end
end
