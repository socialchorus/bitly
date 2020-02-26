module Bitly
  module V4
    class Client
      require 'typhoeus'

      def initialize(access_token, timeout = nil)
        @timeout = timeout
        @access_token = access_token
        @authority_uri = 'https://api-ssl.bitly.com/v4'
      end

      def shorten(long_url, opts = {})
        query = ->(url) { { body: { long_url: url }.merge(opts).to_json } }

        request = if long_url.is_a?(Array)
                    request_array = long_url.map do |url|
                      post('/shorten', query.call(url))
                    end
                    parallel_requests(request_array)
                  else
                    post('/shorten', query.call(long_url)).run
                  end

        Bitly::V4::Url.new(self, request)
      end

      def clicks_summary(short_url, opts = {})
        link = ->(url) { "/bitlinks/#{url}/clicks/summary" }

        request = if short_url.is_a?(Array)
                    request_array = short_url.map do |url|
                      get(link.call(url), opts)
                    end
                    parallel_requests(request_array)
                  else
                    get(link.call(short_url), opts).run
                  end

        Bitly::V4::Url.new(self, request)
      end

      def clicks(short_url, opts = {})
        link = ->(url) { "/bitlinks/#{url}/clicks" }

        request = if short_url.is_a?(Array)
                    request_array = short_url.map do |url|
                      get(link.call(url), opts)
                    end
                    parallel_requests(request_array)
                  else
                    get(link.call(short_url), opts).run
                  end

        Bitly::V4::Url.new(self, request)
      end

      private

      def post(path_uri, opts = {})
        requests(:post, path_uri, opts)
      end

      def get(path_uri, opts = {})
        requests(:get, path_uri, opts)
      end

      def default_headers
        header = {}
        header['Authorization'] = "Bearer #{@access_token}"
        header['Content-Type'] = 'application/json'
        header
      end

      def requests(method, path_uri = '', opts = {})
        Typhoeus::Request.new(
          "#{@authority_uri}#{path_uri}",
          method: method.to_sym,
          body: (opts[:body] || {}),
          params: (opts[:params] || {}),
          headers: (opts[:headers] || {}).merge(default_headers)
        )
      end

      def parallel_requests(request_array)
        hydra = Typhoeus::Hydra.new(max_concurrency: 15)
        requests = request_array.map do |request|
          hydra.queue(request)
          request
        end
        hydra.run
        requests
      end
    end
  end
end
