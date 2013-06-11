module Veronic
	class Config
		attr_accessor  :dnsprovider, :cloudprovider, :configprovider, :dnsprovider_access_key_id, :dnsprovider_secret_access_key, :cloudprovider_access_key_id, :cloudprovider_secret_access_key, :cloudprovider_images_owner_id, :dnsprovider_zones, :region, :availability_zone, :aws_ssh_key_id, :node_name, :client_key, :validation_client_name, :validation_key, :chef_server_url, :ssl_version, :identity_file, :branch, :environment, :ssh_user, :ssh_port, :role, :flavor, :security_groups, :deploy_cmd, :name, :image, :zone_name, :zone_url, :verbose, :query

		def initialize(options={})
			config_file = File.exists?('/etc/veronic/veronic.yml') ? '/etc/veronic/veronic.yml' : '../../' + File.dirname($0) + '/veronic.yml'
			config_from_file = YAML.load_file(options[:config_file] || config_file)

			@dnsprovider                      = :route53
			@cloudprovider                    = :ec2
			@configprovider                   = :chefserver
			@dnsprovider_access_key_id        = options[:dnsprovider_access_key_id]        || config_from_file['dnsprovider_access_key_id']
			@dnsprovider_secret_access_key    = options[:dnsprovider_secret_access_key]    || config_from_file['dnsprovider_secret_access_key']
			@dnsprovider_zones                = options[:dnsprovider_zones]                || config_from_file['dnsprovider_zones']
			@cloudprovider_access_key_id      = options[:cloudprovider_access_key_id]      || config_from_file['cloudprovider_access_key_id']
			@cloudprovider_secret_access_key  = options[:cloudprovider_secret_access_key]  || config_from_file['cloudprovider_secret_access_key']
			@cloudprovider_images_owner_id    = options[:cloudprovider_images_owner_id]    || config_from_file['cloudprovider_images_owner_id']
			@region                           = options[:region]                           || config_from_file['region']
			@availability_zone                = options[:availability_zone]                || config_from_file['availability_zone']
			@aws_ssh_key_id                   = options[:aws_ssh_key_id]                   || config_from_file['aws_ssh_key_id']
			@node_name                        = options[:node_name]                        || config_from_file['node_name']
			@client_key                       = options[:client_key]                       || config_from_file['client_key']
			@validation_client_name           = options[:validation_client_name]           || config_from_file['validation_client_name']
			@validation_key                   = options[:validation_key]                   || config_from_file['validation_key']
			@chef_server_url                  = options[:chef_server_url]                  || config_from_file['chef_server_url']
			@ssl_version                      = options[:ssl_version]                      || config_from_file['ssl_version']
			@identity_file                    = options[:identity_file]                    || config_from_file['identity_file']
			@branch                           = options[:branch]                           || config_from_file['branch']
			@environment                      = options[:environment]                      || config_from_file['environment']
			@ssh_user                         = options[:ssh_user]                         || config_from_file['ssh_user']	|| 'ubuntu'
			@ssh_port                         = options[:ssh_port]                         || config_from_file['ssh_port']	|| 22
			@role                             = options[:role]                             || config_from_file['role']
			@flavor                           = options[:flavor]                           || config_from_file['flavor'] || 'm1.medium'
			@security_groups                  = options[:security_groups].split(',')       || config_from_file['security_groups'].split(',')
			@deploy_cmd                       = options[:deploy_cmd]                       || config_from_file['deploy_cmd'] || 'sudo chef-client'
			@name                             = (options[:branch] || config_from_file['branch']) ? (options[:branch] 	|| config_from_file['branch']) : (options[:name] || config_from_file['name'])
			@image                            = options[:ami_image]                        || config_from_file['ami_image']
			@verbose                          = options[:verbose]                          || config_from_file['verbose']
			@query                            = options[:query]                            || config_from_file['query']
		end

		def to_hash
			hash = {}
			self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
			return hash
		end
	end
end