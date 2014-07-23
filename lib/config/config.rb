# encoding: utf-8
module Veronic
  # Grabs and stores the configuration in memory
  class Config
    attr_accessor :availability_zone,
                  :aws_ssh_key_id,
                  :branch,
                  :chef_server_url,
                  :client_key,
                  :cloudprovider,
                  :cloudprovider_access_key_id,
                  :cloudprovider_images_owner_id,
                  :cloudprovider_secret_access_key,
                  :config_file,
                  :configprovider,
                  :deploy_cmd,
                  :dnsprovider,
                  :dnsprovider_access_key_id,
                  :dnsprovider_secret_access_key,
                  :dnsprovider_zones,
                  :environment,
                  :flavor,
                  :identity_file,
                  :image,
                  :name,
                  :node_name,
                  :query,
                  :region,
                  :role,
                  :security_groups,
                  :ssh_port,
                  :ssh_user,
                  :ssl_version,
                  :validation_client_name,
                  :validation_key,
                  :verbose,
                  :zone_name,
                  :zone_url

    DEFAULT_OPTIONS = {
      :cloudprovider   => :ec2,
      :configprovider  => :chefserver,
      :deploy_cmd      => 'sudo chef-client',
      :dnsprovider     => :route53,
      :flavor          => 'm1.medium',
      :security_groups => 'default',
      :ssh_port        => 22,
      :ssh_user        => 'ubuntu'
    }

    def initialize(options = {})
      config                   = DEFAULT_OPTIONS.merge(load_config(options[:config_file] || '/etc/veronic/veronic.yml')).merge(options)

      config[:image]         ||= config.delete(:ami_image)
      config[:name]            = config[:branch] if config[:branch]
      config[:security_groups] = config[:security_groups].split(',')

      config.each_pair do |option, value|
        send("#{option}=", value)
      end
    end

    def to_hash
      instance_variables.each_with_object({}) { |var, h| h[var.to_s.delete('@').to_sym] = instance_variable_get(var) }
    end

    private

    def load_config(config_file)
      if File.exist?(config_file)
        YAML.load_file(config_file).each_with_object({}) do |(k, v), memo|
          memo[k.to_sym] = v if v && !v.empty?
          memo
        end
      else
        {}
      end
    end
  end
end
