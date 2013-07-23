module Provider
	class Ec2
		class Instance

			def initialize(ec2, name, image)
				@ec2 = ec2
				@name = name
		    @instance = instance
        @ami_name = image || name
		  end

			def stop
				print "Stopping instance #{@name}..."
				if self.exist?
					@instance.stop
					i = 0
					while self.status != :stopped
            print "." ; sleep 3 ; i += 1
						return false if i > 120
					end
          puts "\nInstance #{@name} is stopped"
				end
				return true
			end

			def start
				print "Starting instance #{@name}..."
				if self.exist?
					while self.status == :stopping
						sleep 2
					end
					@instance.start
					i = 0 					
					while self.status != :running
						print "." ; sleep 3 ; i += 1
						return false if i > 120
					end
          puts "\nInstance #{@name} is started"
				end
        return true
			end

			def exists?
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
				@instance.status if @instance
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

			def instance
				@instance ||= get_instance
			end

			def get_instance
				AWS.memoize do
					@ec2.instances.select {|x| x.tags['Name'] == @name && x.status != :shutting_down && x.status != :terminated}.first
				end
			end

			def create_image
				puts "Create image #{@ami_name}"
				new_image = @instance.create_image(@ami_name, { :no_reboot => true })
				while new_image.exists? == false && new_image.state != :failed
					print "."
					sleep 1
				end
				while new_image.state == :pending && new_image.state != :failed
					print "."
					sleep 1
				end
				puts ""
				return new_image
			end

			def tags(hash={})
				puts "Tagging instance ..."
				hash.keys.each do |k|
					puts k + ': ' + hash[k]
					@instance.tags[k] = hash[k]
				end
			end
					
		end
	end
end