module Provider
	class ChefServer
		class Client

			def initialize(name)
				@name = name
			end

			def destroy(name=nil)
				puts "Destroying client #{@name} from chef-server ..."
				knife = Chef::Knife.new()
				knife.config[:yes] = true
				if self.exists?
					knife.delete_object(Chef::ApiClient, @name)
					puts "Client #{@name} destroy from chef-server"
				else
					puts "Unabled to find client #{@name}"
				end
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