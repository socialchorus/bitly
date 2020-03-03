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
                      { request: post('/shorten', query.call(url)), metadata: { long_url: url } }
                    end
                    parallel_requests(request_array)
                  else
                    { request: post('/shorten', query.call(long_url)).run, metadata: { long_url: long_url } }
                  end

        Bitly::V4::Url.new(self, request)
      end

      def clicks_summary(short_url, opts = {})
        link = ->(url) { "/bitlinks/#{url}/clicks/summary" }

        request = if short_url.is_a?(Array)
                    request_array = short_url.map do |url|
                      { request: get(link.call(to_bitly_id(url)), opts), metadata: { short_url: url } }
                    end
                    parallel_requests(request_array)
                  else
                    { request: get(link.call(to_bitly_id(short_url)), opts).run, metadata: {short_url: short_url} }
                  end

        Bitly::V4::Url.new(self, request)
      end

      def clicks(short_url, opts = {})
        link = ->(url) { "/bitlinks/#{url}/clicks" }

        request = if short_url.is_a?(Array)
                    request_array = short_url.map do |url|
                      { request: get(link.call(url), opts), metadata: { short_url: url } }
                    end
                    parallel_requests(request_array)
                  else
                    { request: get(link.call(short_url), opts).run, metadata: { short_url: short_url} }
                  end

        Bitly::V4::Url.new(self, request)
      end

      private

      def post(path_uri, opts = {})
        request = requests(:post, path_uri, opts)

        request.on_complete do |response|
          unless response.success?
            BitlyError.new(response.return_message, response.code)
          end
        end
        request
      end

      def get(path_uri, opts = {})
        request = requests(:get, path_uri, opts)

        request.on_complete do |response|
          unless response.success?
            BitlyError.new(response.return_message, response.code)
          end
        end
        request
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
        requests = request_array.map do |elem|
          hydra.queue(elem[:request])
          elem
        end
        hydra.run
        requests
      end

      def to_bitly_id(url)
        if url.start_with?('http://') || url.start_with?('https://')
          uri = URI.parse(url)
          "#{uri.host}#{uri.path}"
        else
          url
        end
      end
    end
  end
end
