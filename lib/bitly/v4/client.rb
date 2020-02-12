module Bitly
  module V4
    # The client is the main part of this gem. You need to initialize the client with your
    # username and API key and then you will be able to use the client to perform
    # all the rest of the actions available through the API.
    class Client
      include HTTParty
      base_uri 'https://api-ssl.bitly.com/v4/'

      # Requires a generic OAuth2 access token or -deprecated- login and api key.
      # http://dev.bitly.com/authentication.html#apikey
      # Generic OAuth2 access token: https://bitly.com/a/oauth_apps
      # ApiKey: Get yours from your account page at https://bitly.com/a/your_api_key
      # Visit your account at http://bit.ly/a/account
      def initialize(*args)
        args.compact!
        self.timeout = args.last.is_a?(0.class) ? args.pop : nil
        @default_query_opts = if args.count == 1
                                # Set generic OAuth2 access token
                                { access_token: args.first }
                              else
                                # Deprecated ApiKey authentication
                                {
                                  login: args[0],
                                  apiKey: args[1]
                                }
                              end
      end

      # Validates a login and api key
      def validate(x_login, x_api_key)
        response = get('/validate', query: { x_login: x_login, x_apiKey: x_api_key })
        response['data']['valid'] == 1
      end
      alias valid? validate

      # Checks whether a domain is a bitly.Pro domain
      def bitly_pro_domain(domain)
        response = get('/bitly_pro_domain', query: { domain: domain })
        response['data']['bitly_pro_domain']
      end
      alias pro? bitly_pro_domain

      # Shortens a long url
      #
      # Options can be:
      #
      # [domain]                choose bit.ly or j.mp (bit.ly is default)
      #
      # [x_login and x_apiKey]  add this link to another user's history (both required)
      #
      def shorten(long_url, opts = {})
        query = { longUrl: long_url }.merge(opts)
        response = get('/shorten', query: query)
        Bitly::V4::Url.new(self, response['data'])
      end

      # Expands either a hash, short url or array of either.
      #
      # Returns the results in the order they were entered
      def expand(input)
        get_method(:expand, input)
      end

      # Expands either a hash, short url or array of either and gets click data too.
      #
      # Returns the results in the order they were entered
      def clicks(input)
        get_method(:clicks, input)
      end

      # Like expand, but gets the title of the page and who created it
      def info(input)
        get_method(:info, input)
      end

      # Looks up the short url and global hash of a url or array of urls
      #
      # Returns the results in the order they were entered
      def lookup(input)
        input = arrayize(input)
        query = input.inject([]) { |q, i| q << "url=#{CGI.escape(i)}" }
        query = '/lookup?' + query.join('&')
        response = get(query)
        results = response['data']['lookup'].each_with_object([]) do |url, rs|
          url['long_url'] = url['url']
          url['url'] = nil
          if url['error'].nil?
            # builds the results array in the same order as the input
            rs[input.index(url['long_url'])] = Bitly::V4::Url.new(self, url)
            # remove the key from the original array, in case the same hash/url was entered twice
          else
            rs[input.index(url['long_url'])] = Bitly::V4::MissingUrl.new(url)
          end
          input[input.index(url['long_url'])] = nil
        end
        results.length > 1 ? results : results[0]
      end

      # Expands either a short link or hash and gets the referrer data for that link

      # This method does not take an array as an input
      def referrers(input)
        get_single_method('referrers', input)
      end

      # Expands either a short link or hash and gets the country data for that link

      # This method does not take an array as an input
      def countries(input)
        get_single_method('countries', input)
      end

      # Takes a short url, hash or array of either and gets the clicks by minute of each of the last hour
      def clicks_by_minute(input)
        get_method(:clicks_by_minute, input)
      end

      # Takes a short url, hash or array of either and gets the clicks by day
      def clicks_by_day(input, opts = {})
        opts.select! { |k, _v| k.to_s == 'days' }
        get_method(:clicks_by_day, input, opts)
      end

      def timeout=(timeout = nil)
        self.class.default_timeout(timeout) if timeout
      end

      private

      def arrayize(arg)
        if arg.is_a?(String)
          [arg]
        else
          arg.dup
        end
      end

      def get(method, opts = {})
        opts[:query] ||= {}
        opts[:query].merge!(@default_query_opts)

        begin
          response = self.class.get(method, opts)
        rescue Timeout::Error
          raise BitlyTimeout.new("Bitly didn't respond in time", '504')
        end

        if response['status_code'] == 200
          response
        else
          raise BitlyError.new(response['status_txt'], response['status_code'])
        end
      end

      def is_a_short_url?(input)
        input.match(%r{^https?://})
      end

      def get_single_method(method, input)
        unless input.is_a? String
          raise ArgumentError, 'This method only takes a hash or url input'
        end

        query = if is_a_short_url?(input)
                  "shortUrl=#{CGI.escape(input)}"
                else
                  "hash=#{CGI.escape(input)}"
                end
        query = "/#{method}?" + query
        response = get(query)
        Bitly::V4::Url.new(self, response['data'])
      end

      def get_method(method, input, opts = {})
        input = arrayize(input)
        query = input.inject([]) do |q, i|
          q << if is_a_short_url?(i)
                 "shortUrl=#{CGI.escape(i)}"
               else
                 "hash=#{CGI.escape(i)}"
               end
        end
        query = opts.inject(query) do |q, (k, v)|
          q << "#{k}=#{v}"
        end
        query = "/#{method}?" + query.join('&')
        response = get(query)
        results = response['data'][method.to_s].each_with_object([]) do |url, rs|
          result_index = input.index(url['short_url'] || url['hash']) || input.index(url['global_hash'])
          if url['error'].nil?
            # builds the results array in the same order as the input
            rs[result_index] = Bitly::V4::Url.new(self, url)
            # remove the key from the original array, in case the same hash/url was entered twice
          else
            rs[result_index] = Bitly::V4::MissingUrl.new(url)
          end
          input[result_index] = nil
        end
        results.length > 1 ? results : results[0]
      end
    end
  end
end

class BitlyTimeout < BitlyError; end
