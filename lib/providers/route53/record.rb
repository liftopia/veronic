module Route53
	class Zone
		class Record

			def initialize(zone, name, values=[], type, ttl)
				@zone = zone
				@name = name
				@values = values
				@type =  type
				@ttl = ttl
			end
			
			def get
				@zone.records.select {|x| x.name == @name+'.'}.first
			end

			def exist?
				@zone.records.any? {|x| x.name == @name+'.'}
			end

			def match?
				@zone.records.any? {|x| x.name == @name+'.' && x.values == @values}
			end

			def wait_set
				print "Waitting for record { name: #{@name}, value: #{@values} }..."
				while !self.match?
					print "."
					self.set
					sleep 5
				end
				puts "\nRecord { name: #{@name}, value: #{@values} } updated"
			end

			def set
				if self.exist?
					record = self.get
					new_record = Route53::DNSRecord.new(record.name, record.type, record.ttl, record.values, @zone)
					record.update(@name, @type, @ttl, @values, @zone)
				else
					record = Route53::DNSRecord.new(@name, @type, @ttl, @values, @zone)
					record.create
				end
			end

			def delete
				if self.exist?
					record = Route53::DNSRecord.new(@name, @type, @ttl, @values, @zone)
					record.delete
				end
			end
			
		end
	end
end