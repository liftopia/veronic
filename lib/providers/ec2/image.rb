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
						sleep 5
						puts "Image #{@ami_name} destroyed"
					rescue
						return false
					end
				end
				return true
			end

			def image
				puts "Getting image #{@ami_name}..."
				@image ||= get_image
			end

			def get_image
				AWS.memoize do
					my_image = @ec2.images.with_owner(@owner_id).select {|x| x.name == @ami_name}.first
					unless my_image
						my_image = @ec2.images[@ami_name]
						unless my_image.exists?
							return false
						end
					else
						while my_image.exists? == false && my_image.state != :failed
							print "."
							sleep 1
						end
						while my_image.state == :pending && my_image.state != :failed
							print "."
							sleep 1
						end
						puts ""
					end
					return my_image
				end
			end

		end
	end
end