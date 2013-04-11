module Route53
	class Zone

		def record(name, values=[], type, ttl)
			Route53::Zone::Record.new(self, name, values, type, ttl)
		end

		def records
			self.get_records
		end

	end
end