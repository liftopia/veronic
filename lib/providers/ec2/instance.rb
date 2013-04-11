module Provider
	class Ec2
		class Instance

			def initialize(ec2, name)
				@ec2 = ec2
				@name = name
		        @instance = @ec2.instances.select {|x| x.tags['Name'] == @name && x.status != :shutting_down && x.status != :terminated}.first
		    end

			def stop
				print "Stopping instance #{@name}..."
				if @instance.exist && @instance.status == :running
					@instance.stop
					@i = 0
					while @instance.status != :stopped && @i < 40
						print "." ; sleep 3 ; @i += 1
					end
				end
				puts "\nInstance #{@name} is stopped"
			end

			def start
				print "Starting instance #{@name}..."
				if @instance.exist && @instance.status == :stopped
					@instance.start
					@i = 0 					
					while @instance.status != :running && @i < 40
						print "." ; sleep 3 ; @i += 1
					end
				end
				puts "\nInstance #{@name} is started"
			end

			def exist?
				puts "Checking for ec2 server #{@name} ..."
				if @ec2.instances.any? {|x| x.tags['Name'] == @name && x.status != :shutting_down && x.status != :terminated}
					puts "Instance #{@name} found"
					return true
				else
					puts "Instance #{@name} is misssing"
					return false
				end
			end

			def status
				begin
					@instance.status
				rescue Exception => e
					return :missing
				end
			end

			def dns_name
				@instance.dns_name
			end

			def public_ip_address
				@instance.public_ip_address
			end

			def id
				@instance.id
			end
					
		end
	end
end