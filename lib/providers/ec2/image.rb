module Provider
	class Ec2
		class Image

			def initialize(ec2, environment, owner_id, name=nil)
				@ec2 = ec2
				@environment = environment
				@name = name
				@ami_name = @name || @environment + '-ami'
				@owner_id = owner_id
			end

			def id
				if image
					@image.id
				end
			end

			def detroy
				puts "Destroying image #{@ami_name}..."
				if image
					begin
						@image.deregister
						puts "Image #{@ami_name} destroyed"
					rescue
						return false
					end
				end
				return true
			end

			def image
				puts "Getting image #{@ami_name}..."
				@image = get_image
				unless @image
					sleep 5
					@image = get_image
				end
				if @image
					while @image.exists? == false && @image.state != :failed
						print "."
						sleep 1
					end
					while @image.state == :pending && @image.state != :failed
						print "."
						sleep 1
					end
					puts ""
					return @image
				else
					return false
				end
			end

			def get_image
				@ec2.images.with_owner(@owner_id).select {|x| x.name == @ami_name}.first
			end

		end
	end
end