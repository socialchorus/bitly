module Bitly
  module V4
    # Url objects should only be created by the client object as it collects the correct information
    # from the API.
    class Url
      attr_reader :short_url, :long_url, :user_clicks

      # Initialize with a bitly client and hash to fill in the details for the url.
      def initialize(client, data)
        @client = client
        @short_url = data['link']
        @long_url = data['long_url']
        @user_clicks = data['total_clicks']
      end
    end
  end
end
