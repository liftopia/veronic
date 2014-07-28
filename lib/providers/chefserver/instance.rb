module Provider
  class ChefServer
    class Instance

      def initialize(config)
        @access_key_id                                = config[:cloudprovider_access_key_id]
        @secret_access_key                            = config[:cloudprovider_secret_access_key]
        @name                                         = config[:name]
        @image                                        = config[:image]
        @security_groups                              = config[:security_groups]
        @ssh_user                                     = config[:ssh_user]
        @ssh_port                                     = config[:ssh_port]
        @identity_file                                = config[:identity_file]
        @aws_ssh_key_id                               = config[:aws_ssh_key_id]
        @environment                                  = config[:environment]
        @role                                         = config[:role]
        @roles                                        = "role[#{config[:role]}]"
        @flavor                                       = config[:flavor]
        @region                                       = config[:region]
        @availability_zone                            = config[:availability_zone]
        @verbose                                      = config[:verbose]
        Chef::Config[:knife][:image]                  = @image
        Chef::Config[:knife][:aws_ssh_key_id]         = @aws_ssh_key_id
        Chef::Config[:knife][:aws_access_key_id]      = @access_key_id
        Chef::Config[:knife][:aws_secret_access_key]  = @secret_access_key
        Chef::Config[:knife][:region]                 = @region
        Chef::Config[:knife][:availability_zone]      = @availability_zone
        Chef::Config[:knife][:log_level]              = @verbose
        @logger = Veronic::Deployer.new().logger
      end

      def create
        @logger.info "Creating ec2 server #{@name} ..."
        
        node = Chef::Knife::Ec2ServerCreate.new()

        node.config[:run_list]          = [@roles]
        node.config[:image]             = @image
        node.config[:flavor]            = @flavor
        node.config[:security_groups]   = @security_groups
        node.config[:ssh_user]          = @ssh_user
        node.config[:ssh_port]          = @ssh_port
        node.config[:chef_node_name]    = @name
        node.config[:identity_file]     = @identity_file
        node.config[:environment]       = @environment
        node.config[:log_level]         = @verbose

        @logger.info node.config
        node.run
      end

      def bootstrap(recursive_count=0)
        @logger.info "Bootstrapping ec2 server #{@name} ..."
        
        node = Chef::Knife::Ec2ServerCreate.new()

        node.config[:image]             = @image
        node.config[:flavor]            = @flavor
        node.config[:security_groups]   = @security_groups
        node.config[:ssh_user]          = @ssh_user
        node.config[:ssh_port]          = @ssh_port
        node.config[:chef_node_name]    = @name
        node.config[:identity_file]     = @identity_file
        node.config[:environment]       = @environment
        node.config[:log_level]         = @verbose
        node.config[:template_file]     = '/etc/veronic/bootstrap/lifted-chef.erb'

        @logger.info node.config
        begin
          node.run
        rescue => e
          @logger.info "Creation of #{@name} failed"
          @logger.info "Message: " + e.inspect
          @logger.info "Stacktrace:#{e.backtrace.map {|l| "  #{l}\n"}.join}"
          self.destroy([node.server.id]) if node.server
          if recursive_count < 10
            @logger.info "Creation of #{@name} retrying #{recursive_count}"
            self.bootstrap(recursive_count+=1) 
          else
            @logger.info "Creation of #{@name} failed after #{recursive_count} retry"
            exit 1
          end
        end
      end

      def destroy(instance_ids=[])
        @logger.info "Deleting ec2 server #{@name} ..."

        node = Chef::Knife::Ec2ServerDelete.new()

        node.config[:purge]           = true
        node.config[:chef_node_name]  = @name
        node.config[:yes]             = true
        node.name_args                = instance_ids

        @logger.info node.config
        node.run
        node.destroy_item(Chef::Node, @name, "node")
        node.destroy_item(Chef::ApiClient, @name, "client")
      end

      def set_role
        node = Chef::Knife::NodeRunListAdd.new()
        node.name_args = [@name, @roles]
        node.run
      end

      def set_environment
        node = Chef::Node.new.tap do |n|
          n.name( @name )
          n.chef_environment( @environment )
        end
        node.save
        @logger.info "Environment: #{@environment}"
      end

      def ssh(query, cmd_line, manual)
        knife_ssh = Chef::Knife::Ssh.new()

        knife_ssh.config[:manual]         = manual
        knife_ssh.config[:ssh_user]       = @ssh_user
        knife_ssh.config[:identity_file]  = @identity_file
        knife_ssh.config[:log_level]      = @verbose
        
        unless manual
          if @environment
            query += "#{query.empty? ? '' : ' AND'} chef_environment:#{@environment}"
          end
          if @role
            query += "#{query.empty? ? '' : ' AND'} role:#{@role}"
          end
        end

        knife_ssh.name_args = [query, cmd_line]
        sys_status =  knife_ssh.run
      end

      def client
        Provider::ChefServer::Client.new(@name)
      end

      def delete_client_key(node, client_key="/etc/chef/client.pem")
        @logger.info "Deleting client_key #{client_key}"
        self.ssh(node, "sudo chef-client -W > /dev/null ; sudo rm -f #{client_key}", true)
      end
    end
  end
end
