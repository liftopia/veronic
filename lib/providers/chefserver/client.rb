module Provider
	class ChefServer
		class Client

			def initialize(name)
				@name = name
			end

			def destroy(name=nil)
				puts "Destroying client #{@name} ..."
				
				knife = Chef::Knife.new()
				knife.config[:yes] = true
				knife.delete_object(Chef::ApiClient, @name) if self.exists?
			end

			def exists?
				begin
					Chef::ApiClient.load(@name)
				rescue					
					return false
				end		
				return true
			end
		end
	end
end