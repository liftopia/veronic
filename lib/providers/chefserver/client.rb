module Provider
	class ChefServer
		class Client

			def initialize(name)
				@name = name
				@logger = Veronic::Deployer.new().logger
			end

			def destroy(name=nil)
				@logger.info "Destroying client #{@name} from chef-server ..."
				knife = Chef::Knife.new()
				knife.config[:yes] = true
				if self.exists?
					knife.delete_object(Chef::ApiClient, @name)
					@logger.info "Client #{@name} destroy from chef-server"
				else
					@logger.info "Unabled to find client #{@name}"
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