# encoding: utf-8
require_relative 'config/config'
require_relative 'providers/cloudprovider'
require_relative 'providers/dnsprovider'
require_relative 'providers/configprovider'
require 'logger'

# Racecar
module Veronic
  # Handles all the deploy functions
  class Deployer
    def initialize(options = {})
      @config = config(options)
      @logger = logger
    end

    def logger
      $stderr.sync = true
      Logger.new($stderr)
    end

    def config(options = {})
      @config || Veronic::Config.new(options)
    end

    def configprovider
      ConfigProvider.new(@config.to_hash)
    end

    def dnsprovider
      DnsProvider.new(@config.to_hash)
    end

    def cloudprovider
      CloudProvider.new(@config.to_hash)
    end

    def create
      configprovider.instance.create unless bootstrap
    end

    def deploy_stacks
      deploy_cmd = "sudo chef-client #{@config.verbose ? '-l ' + @config.verbose : ''}"
      manual     = true
      query      = cloudprovider.instance.dns_name

      configprovider.ssh(query, deploy_cmd, manual)
    end

    def deploy_apps
      deploy_stacks if bootstrap

      deploy_cmd = "sudo chef-client -o 'recipe[lift_envs::app_deploy]' #{@config.verbose ? '-l ' + @config.verbose : ''}"
      manual     = true
      query      = cloudprovider.instance.dns_name

      configprovider.ssh(query, deploy_cmd, manual)
    end

    def run_tests
      if bootstrap
        deploy_stacks
        deploy_apps
      end

      deploy_cmd = "sudo chef-client -o 'recipe[lift_envs::app_testing]' #{@config.verbose ? '-l ' + @config.verbose : ''}"
      manual     = true
      query      = cloudprovider.instance.dns_name

      configprovider.ssh(query, deploy_cmd, manual)
    end

    def destroy
      @config.dnsprovider_zones.each do |z|
        @config.zone_name = z['zone_name']
        @config.zone_url  = z['zone_url']
        dns               = "#{@config.name}.#{@config.zone_name}"

        logged("Deleting #{dns}") { dnsprovider.zone.record(dns, [], 'A', '1').delete }
      end

      instance_ids = []
      instance_ids << cloudprovider.instance.id if cloudprovider.instance.exists?

      configprovider.instance.destroy(instance_ids)
    end

    def deploy
      config_required(:deploy_cmd)

      bootstrap

      manual = true
      query  = cloudprovider.instance.dns_name

      configprovider.ssh(query, @config.deploy_cmd, manual)
    end

    def search_and_deploy
      config_required(:deploy_cmd, :query)

      manual = false
      query  = @config.query

      configprovider.ssh(query, @config.deploy_cmd, manual)
    end

    def update_instance_dns
      if @config.dnsprovider_zones
        @config.dnsprovider_zones.each do |z|
          @config.zone_name = z['zone_name']
          @config.zone_url  = z['zone_url']
          dns               = "#{@config.name}.#{@config.zone_name}"

          logged("Setting DNS #{dns}") { dnsprovider.zone.record(dns, [cloudprovider.instance.dns_name], 'CNAME', '1').wait_set }
        end
      else
        @logger.info 'Unable to update DNS'
      end
    end

    def instances_list
      cloudprovider.instances_list
    end

    def stop
      cloudprovider.instance.stop
    end

    def start
      exit 1 unless cloudprovider.instance.start == false
    end

    def status
      config_required(:name)

      cloudprovider.instance.status
    end

    def bootstrap
      status = false

      if cloudprovider.instance.status == :running
        @logger.info "#{@config.name} is running"
      elsif cloudprovider.instance.status == :stopped
        start
      elsif cloudprovider.instance.exists? == false
        @config.availability_zone = get_availability_zone
        get_image
        configprovider.instance.client.destroy
        configprovider.instance.bootstrap
        status = true
      else
        fail('Bootstrap failed.')
      end
      set_node

      status
    end

    def create_image
      configprovider.instance.delete_client_key(cloudprovider.instance.dns_name)
      configprovider.instance.client.destroy
      cloudprovider.image.detroy
      cloudprovider.instance.create_image
    end

    def set_node
      update_instance_dns
      if @config.role && @config.environment
        configprovider.instance.set_environment
        configprovider.instance.set_role
        cloudprovider.instance.tags({'role' => @config.role, 'environment' => @config.environment})
        if configprovider.instance.delete_client_key(cloudprovider.instance.dns_name)
          configprovider.instance.client.destroy
        end
      else
        @logger.info 'Unable to set_node arguments --role or --environment is missing'
      end
    end

    def get_image
      abort('Arguments --ami_image is missing') if @config.image.nil?

      @config.image = cloudprovider.image.id
    end

    def get_availability_zone
      @logger.info "Getting availability zone ..."
      environments = {}
      if @config.availability_zone.nil? || @config.availability_zone == 'auto'
        cloudprovider.regions.each do |region|
          region.instances.each do |instance|
            if instance.tags[:environment] && instance.tags[:role] && instance.status != :shutting_down && instance.status != :terminated
              environments[instance.tags[:environment]] = {} unless environments[instance.tags[:environment]]
              environments[instance.tags[:environment]][instance.tags[:role]] = {} unless environments[instance.tags[:environment]][instance.tags[:role]]
              environments[instance.tags[:environment]][instance.tags[:role]][region.name] = {} unless environments[instance.tags[:environment]][instance.tags[:role]][region.name]
              region.availability_zones.each do |availability_zone|
                environments[instance.tags[:environment]][instance.tags[:role]][region.name][availability_zone.name] = [] unless environments[instance.tags[:environment]][instance.tags[:role]][region.name][availability_zone.name]
              end
              environments[instance.tags[:environment]][instance.tags[:role]][region.name][instance.availability_zone] << instance.id
            end
          end
        end
      end
      if environments[@config.environment] && environments[@config.environment][@config.role] && environments[@config.environment][@config.role][@config.region]
        availability_zones = environments[@config.environment][@config.role][@config.region].sort_by { |availability_zone| availability_zone[1].count }
        @logger.info "Zones: " + availability_zones.to_s
        availability_zone = availability_zones.first
        @logger.info "Zone selected: " + availability_zone[0]
        availability_zone[0]
      end
    end

    private

    def logged(message)
      @logger.info("Started: #{message}")
      ret = yield if block_given?
      @logger.info("Finished: #{message}")
      ret
    end

    def config_required(*keys)
      keys.each do |key|
        fail("Argument --#{key} is missing") unless @config.send(key)
      end
    end
  end
end
