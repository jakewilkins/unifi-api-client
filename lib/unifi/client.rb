require "unifi/client/version"
require 'net/http'
require 'openssl'
require 'json'

module Unifi
  class Client
    attr_reader :username, :password, :cookie, :type
    private :password, :cookie

    def initialize(host: nil, username: ENV['UNIFI_USERNAME'], password: ENV['UNIFI_PASSWORD'], type: :controller)
      @type = type
      host ||= ENV["UNIFI_#{type.to_s.upcase}_HOST"]
      @host = prefix_scheme(host)
      @username, @password = username, password
      @cookie = nil
      @domain = "default"
    end

    def get(path, raw: false)
      login if @cookie.nil?
      uri = uri_for(path)
      http(uri, Net::HTTP::Get.new(uri), raw: raw)
    end

    def post(path, body:, raw: false)
      login if @cookie.nil?
      uri = uri_for(path)
      request = Net::HTTP::Post.new(uri)
      request.body = body
      http(uri, request, raw: raw)
    end

    def put(path, body:, raw: false)
      login if @cookie.nil?
      uri = uri_for(path)
      request = Net::HTTP::Put.new(uri)
      request.body = body
      http(uri, request, raw: raw)
    end

    def login(force: false)
      @cookie = nil if force
      return @cookie if @cookie

      path = type == :controller ? "/api/login" : "/api/2.0/login"
      uri = URI("#@host#{path}")
      req = Net::HTTP::Post.new(uri)
      req.body = JSON.generate({username: username, password: password})
      req['Content-Type'] = 'application/json'

      if type == :video
        req['Cookie'] = get_login_cookie
        req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'
      end

      resp = Net::HTTP.start(uri.host, uri.port, http_start_opts) do |http|
        http.request(req)
      end

      # binding.pry

      cookie = case resp
      when Net::HTTPOK
        return (@cookie = req['Cookie']) if type == :video
        resp['Set-Cookie'].split('; ').find {|c| c[0..7] == 'unifises' || c[0..7] == 'JSESSION'}
      end
      @cookie = cookie
    end

    def uri_for(path)
      URI("#@host#{prefix_path(path)}")
    end

    private

    def http(uri, req = nil, raw: false)
      resp = Net::HTTP.start(uri.host, uri.port, http_start_opts) do |http|
        if block_given?
          yield
        else
          req['Cookie'] = @cookie
          req['Content-Type'] ||= 'application/json'
          req['Accept'] = 'application/json' if req['Accept'] == '*/*'
          http.request(req)
        end
      end

      # binding.pry
      return resp if raw
      case resp
      when Net::HTTPOK
        if resp['Content-Type']&.include?('application/json')
          JSON.parse(resp.body)
        else
          resp.body
        end
      else
        resp
      end
    end

    def get_login_cookie
      uri = URI("#@host/")
      req = Net::HTTP::Get.new(uri).tap {|r| r['Accept'] = 'text/html'}
      resp = http(uri, req, raw: true)
      resp['Set-Cookie'].split('; ').find {|c| c[0..7] == 'JSESSION'}
    end

    def prefix_scheme(host_string)
      host_string = "https://#{host_string}" unless host_string[0..3] == "http"
      host_string
    end

    def prefix_path(path)
      path = "/#{path}" unless path[0] == "/"
      path = path.gsub(":domain", @domain)
      path
    end

    def http_start_opts
      {
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_NONE,
        read_timeout: 20,
        connect_timeout: 10,
        ssl_timeout: 10
      }
    end
  end
end

require 'unifi/camera'
require 'unifi/clients'
require 'unifi/events'
