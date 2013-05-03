require 'aws-sdk'
require_relative 'instance'
require_relative 'image'

module Provider
	class Ec2

		def initialize(config)
			@name                = config[:name]
			@environment         = config[:environment]
			@access_key_id       = config[:cloudprovider_access_key_id]
			@secret_access_key   = config[:cloudprovider_secret_access_key]
			@owner_id            = config[:cloudprovider_images_owner_id]
			@ec2                 = ec2
		end

		def image(name=nil)
			Provider::Ec2::Image.new(@ec2, @environment, @owner_id, name)
		end

		def instance
			Provider::Ec2::Instance.new(@ec2, @name, @environment)
		end

		def instances
			AWS.memoize do
				@instances ||= @ec2.instances
			end
		end

		def ec2
			AWS::EC2.new(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key)
		end

	end
end