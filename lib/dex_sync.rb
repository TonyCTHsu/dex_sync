require 'dex_sync/version'
require 'faraday'
require 'faraday_middleware'
require 'faraday-cookie_jar'
require 'nokogiri'
require 'yaml'

module DexSync
  class Config
    def initialize
      @configuration = YAML.safe_load(File.read(File.expand_path('~/dex_sync.yaml')))
    end

    def dex
      @configuration.fetch('DEX')
    end

    def github
      @configuration.fetch('GITHUB')
    end

    def namespaces
      @configuration.fetch('NAMESPACES')
    end

    def clusters
      @configuration.fetch('CLUSTERS')
    end

    def user_session
      @configuration.fetch('USER_SESSION')
    end

    def gh_session
      @configuration.fetch('GH_SESSION')
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

          config = YAML.safe_load(response.body)

          File.open(File.expand_path("~/.kubeconfigs/#{cluster}-#{namespace}-internal"), 'w') do |f|
            f.write(config.to_yaml)
          end
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
        domain: @config.github,
        path: '/'
      )
    end

    def gh_session_cookie
      HTTP::Cookie.new(
        name: '_gh_sess',
        value: @config.gh_session,
        domain: @config.github,
        path: '/'
      )
    end
  end
end