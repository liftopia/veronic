module Provider
	class R53
		class Zone

			def initialize(r53, zone_name, zone_url)
				@zone_name = zone_name
				@zone_url = zone_url
				@r53 = r53
				@zone =  zone
			end

			def record
				Provider::R53::Zone::Record
			end

			def records
				@zone.get_records
			end

			def zone
				zone = Route53::Zone.new(@zone_name, @zone_url, @r53)
			end

		end
	end
end