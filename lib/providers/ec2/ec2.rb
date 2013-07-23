require 'aws-sdk'
require_relative 'instance'
require_relative 'image'

module Provider
	class Ec2

		def initialize(config)
			@name                = config[:name]
			@region              = config[:region] 
			@role                = config[:role]
			@access_key_id       = config[:cloudprovider_access_key_id]
			@secret_access_key   = config[:cloudprovider_secret_access_key]
			@owner_id            = config[:cloudprovider_images_owner_id]
			@image               = config[:image] || config[:name]
			@ec2                 = ec2
		end

		def image
			Provider::Ec2::Image.new(@ec2, @role, @owner_id, @image)
		end

		def instance
			Provider::Ec2::Instance.new(@ec2, @name, @image)
		end

		def instances
			AWS.memoize do
				@instances ||= @ec2.instances
			end
		end

		def regions
			AWS.memoize do
				@ec2.regions
			end
		end

		def ec2
			AWS.memoize do
				AWS::EC2.new(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key, :region => @region)
			end
		end

	end
end