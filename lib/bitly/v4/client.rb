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
        query = { body: { long_url: long_url }.merge(opts).to_json }
        request = post('/shorten', query)
        Bitly::V4::Url.new(self, request)
      end

      def clicks_summary(short_url, opts = {})
        request = get("/bitlinks/#{short_url}/clicks/summary", opts)
        Bitly::V4::Url.new(self, request)
      end

      def clicks(short_url, opts = {})
        request = get("/bitlinks/#{short_url}/clicks", opts)
        Bitly::V4::Url.new(self, request)
      end

      private

      def post(path_uri, opts = {})
        if path_uri.is_a?(Array)
          path_uri.map { |elem| requests(:post, elem, opts) }
        else
          requests(:post, path_uri, opts).run
        end
      end

      def get(path_uri, opts = {})
        if path_uri.is_a?(Array)
          path_uri.map { |elem| requests(:get, elem, opts) }
        else
          requests(:get, path_uri, opts).run
        end
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
          method: method,
          body: (opts[:body] || {}),
          params: (opts[:params] || {}),
          headers: (opts[:headers] || {}).merge(default_headers)
        )
      end

      def parallel_request(request_array, max_concurrency = 15)
        hydra = Typhoeus::Hydra.new(max_concurrency: max_concurrency)
        requests = request_array.map do |request|
          hydra.queue(request)
        end
        hydra.run
        requests
      end
    end
  end
end
