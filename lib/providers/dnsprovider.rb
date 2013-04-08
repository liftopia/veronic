require_relative 'route53/r53'

class DnsProvider
	
	DNSPROVIDERS = { :route53 => Provider::R53 }

	def initialize(config)
		@config = config
		@dnsprovider = provider
	end

	def provider
		DNSPROVIDERS[@config[:dnsprovider]].new(@config)
	end

	def zone
		@dnsprovider.zone
	end
end