require 'dex_sync/version'
require 'faraday'
require 'faraday_middleware'
require 'faraday-cookie_jar'
require 'nokogiri'
require 'yaml'

module DexSync
  class Config
    def initialize
      @config = YAML.safe_load(File.read(File.expand_path('~/dex_sync.yaml')))
    end

    def dex
      @config.fetch('DEX')
    end

    def domain
      @config.fetch('DOMAIN', 'github.com')
    end

    def namespaces
      @config.fetch('NAMESPACES')
    end

    def download_path
      @config.fetch('DOWNLOAD_PATH', '~/.kubeconfigs')
    end

    def clusters
      @config.fetch('CLUSTERS')
    end

    def user_session
      @config.fetch('USER_SESSION')
    end

    def gh_session
      @config.fetch('GH_SESSION')
    end
  end

  class UpdateKubeConfigService
    def initialize(config)
      @config = config
    end

    def perform
      @config.clusters.each do |cluster|
        login_params = { cross_client: cluster, offline_access: 'yes' }

        puts("Logging into dex app...#{cluster}")
        response = connection.post('login', login_params)
        puts('Wait for it...')

        doc = Nokogiri::HTML(response.body)

        refresh_token = doc.css('form > input[name=refresh_token]').first['value']
        id_token      = doc.css('form > input[name=id_token]').first['value']

        @config.namespaces.each do |namespace|
          puts("Dowloading config for #{cluster}:#{namespace}")

          download_params = {
            refresh_token: refresh_token,
            id_token: id_token,
            namespace: namespace,
            internal: true
          }

          response = connection.post('download', download_params)

          downloaded_config = YAML.safe_load(response.body)

          expanded_path = File.expand_path(@config.download_path + "/#{cluster}-#{namespace}-internal")

          File.open(expanded_path, 'w') { |f| f.write(downloaded_config.to_yaml) }
        end
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: @config.dex) do |f|
        f.use :cookie_jar
        f.use FaradayMiddleware::FollowRedirects, limit: 10
        f.request  :url_encoded
        f.adapter  Faraday.default_adapter
        f.headers['Cookie'] = HTTP::Cookie.cookie_value(cookie_jar.cookies)
      end
    end

    def cookie_jar
      HTTP::CookieJar.new.tap do |jar|
        jar.add(user_session_cookie)
        jar.add(gh_session_cookie)
      end
    end

    def user_session_cookie
      HTTP::Cookie.new(
        name: 'user_session',
        value: @config.user_session,
        domain: @config.domain,
        path: '/'
      )
    end

    def gh_session_cookie
      HTTP::Cookie.new(
        name: '_gh_sess',
        value: @config.gh_session,
        domain: @config.domain,
        path: '/'
      )
    end
  end
end
