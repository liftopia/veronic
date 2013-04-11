class Chef
  class REST
    class RESTRequest
    	def configure_http_client
        http_proxy = proxy_uri
        if http_proxy.nil?
          @http_client = Net::HTTP.new(host, port)
        else
          Chef::Log.debug("Using #{http_proxy.host}:#{http_proxy.port} for proxy")
          user = Chef::Config["#{url.scheme}_proxy_user"]
          pass = Chef::Config["#{url.scheme}_proxy_pass"]
          @http_client = Net::HTTP.Proxy(http_proxy.host, http_proxy.port, user, pass).new(host, port)
        end
        if url.scheme == HTTPS
          @http_client.use_ssl = true
          if config[:ssl_version] == :SSLv3
          	@http_client.ssl_version = :SSLv3
          end
          if config[:ssl_verify_mode] == :verify_none
            @http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
          elsif config[:ssl_verify_mode] == :verify_peer
            @http_client.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end
          if config[:ssl_ca_path]
            unless ::File.exist?(config[:ssl_ca_path])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_path #{config[:ssl_ca_path]} does not exist"
            end
            @http_client.ca_path = config[:ssl_ca_path]
          elsif config[:ssl_ca_file]
            unless ::File.exist?(config[:ssl_ca_file])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_ca_file #{config[:ssl_ca_file]} does not exist"
            end
            @http_client.ca_file = config[:ssl_ca_file]
          end
          if (config[:ssl_client_cert] || config[:ssl_client_key])
            unless (config[:ssl_client_cert] && config[:ssl_client_key])
              raise Chef::Exceptions::ConfigurationError, "You must configure ssl_client_cert and ssl_client_key together"
            end
            unless ::File.exists?(config[:ssl_client_cert])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_client_cert #{config[:ssl_client_cert]} does not exist"
            end
            unless ::File.exists?(config[:ssl_client_key])
              raise Chef::Exceptions::ConfigurationError, "The configured ssl_client_key #{config[:ssl_client_key]} does not exist"
            end
            @http_client.cert = OpenSSL::X509::Certificate.new(::File.read(config[:ssl_client_cert]))
            @http_client.key = OpenSSL::PKey::RSA.new(::File.read(config[:ssl_client_key]))
          end
        end

        @http_client.read_timeout = config[:rest_timeout]
      end
  	end
  end
end