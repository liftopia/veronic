require 'route53'
require_relative 'zone'
require_relative 'record'

module Provider
	class R53

		def initialize(config)
			@access_key_id = config[:dnsprovider_access_key_id]
			@secret_access_key = config[:dnsprovider_secret_access_key]
			@zone_name = config[:dnsprovider_zone_name]
			@zone_url = config[:dnsprovider_zone_url]
			@r53 = r53
			@zone = zone
		end
		
		def r53
			Route53::Connection.new(@access_key_id, @secret_access_key)
		end

		def zone
			Provider::R53::Zone.new(@r53, @zone_name, @zone_url)
		end
		
	end
end