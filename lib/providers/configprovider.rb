require_relative 'chefserver/chefserver'

class ConfigProvider
	
	CONFIGPROVIDERS = { :chefserver => Provider::ChefServer }

	def initialize(config)
		@config = config
		@provider = provider
	end

	def provider
		CONFIGPROVIDERS[@config[:configprovider]].new(@config)
	end

	def ssh(query, deploy_cmd, manual)
		@provider.ssh(query, deploy_cmd, manual)
	end

	def instance
		@provider.instance
	end

	def client
		@provider.client
	end
end