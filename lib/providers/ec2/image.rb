module Provider
	class Ec2
		class Image

			def initialize(ec2, environment, owner_id)
				@image = ec2.images.with_owner(owner_id).select {|x| x.name == environment + '-ami'}.first	
			end

			def id
				@image.id
			end

		end
	end
end