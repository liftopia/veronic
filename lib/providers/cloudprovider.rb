require_relative 'ec2/ec2'

class CloudProvider
	
	CLOUDPROVIDERS = { :ec2 => Provider::Ec2 }

	def initialize(config)
		@config = config
		@provider = provider
	end

	def provider
		CLOUDPROVIDERS[@config[:cloudprovider]].new(@config)
	end

	def image(name=nil)
		@provider.image(name)
	end

	def instance
		@provider.instance
	end

	def instances
		@provider.instances
	end

	def instances_list
		printf "%17s %35s %34s\n", 'NAME', 'DNS', 'STATUS'
		@provider.instances.each do |instance|
			printf "%-30s %-50s %s\n", instance.tags['Name'], instance.dns_name, instance.status.to_s
		end
	end
end