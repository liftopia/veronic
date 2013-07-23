module Provider
	class Ec2
		class Image

			def initialize(ec2, role, owner_id, ami_name)
				@ec2 = ec2
				@role = role
				@ami_name = ami_name
				@owner_id = owner_id
				@logger = Veronic::Deployer.new().logger
			end

			def id
				if get_image
					get_image.id
				end
			end

			def detroy
				@logger.info "Destroying image #{@ami_name} ..."
				if get_image
					begin
						get_image.deregister
						sleep 5
						@logger.info "Image #{@ami_name} destroyed"
					rescue
						return false
					end
				end
				return true
			end

			def exists?
				get_image
			end

			def get_image
				@get_image || AWS.memoize do
          @logger.info "Getting image #{@ami_name}"
					my_image = @ec2.images.with_owner(@owner_id).select {|x| x.name == @ami_name}.first
					unless my_image
						my_image = @ec2.images[@ami_name]
						unless my_image.exists?
              @logger.info "Unabled to found image #{@ami_name}"
							return false
						end
					else
						while my_image.exists? == false && my_image.state != :failed
							@logger.info "."
							sleep 1
						end
						while my_image.state == :pending && my_image.state != :failed
							@logger.info "."
							sleep 1
						end
						@logger.info ""
					end
          @get_image = my_image
					return @get_image
				end
			end

		end
	end
end