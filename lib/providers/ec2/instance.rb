module Provider
	class Ec2
		class Instance

			def initialize(ec2, name)
				@ec2 = ec2
				@name = name
		       	@instance = instance
		    end

			def stop
				print "Stopping instance #{@name}..."
				if self.exist?
					@instance.stop
					@i = 0
					while self.status != :stopped
						if @i > 120 
							return false
						end
						print "." ; sleep 3 ; @i += 1
					end
				end
				puts "\nInstance #{@name} is stopped"
			end

			def start
				print "Starting instance #{@name}..."
				if self.exist?
					while self.status == :stopping
						sleep 2
					end
					@instance.start
					@i = 0 					
					while self.status != :running
						if @i > 120 
							return false
						end
						print "." ; sleep 3 ; @i += 1
					end
				end
				puts "\nInstance #{@name} is started"
			end

			def exist?
				puts "Checking for ec2 server #{@name} ..."
				if AWS.memoize do @ec2.instances.any? {|x| x.tags['Name'] == @name && x.status != :shutting_down && x.status != :terminated} end
					puts "Instance #{@name} found"
					return true
				else
					puts "Instance #{@name} is misssing"
					return false
				end
			end

			def status
				@instance.status
			end

			def dns_name
				@instance.dns_name
			end

			def public_ip_address
				@instance.public_ip_address
			end

			def id
				@id ||= get_instance.id
			end

			def instance
				@ec2.instances[id]
			end

			def get_instance
				AWS.memoize do
					@ec2.instances.select {|x| x.tags['Name'] == @name && x.status != :shutting_down && x.status != :terminated}.first
				end
			end
					
		end
	end
end