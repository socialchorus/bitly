module Bitly
  module V4
    # Url objects should only be created by the client object as it collects the correct information
    # from the API.
    class Url
      attr_reader :client, :data, :results

      # Initialize with a bitly client and hash to fill in the details for the url.
      def initialize(client, data)
        @data = data
        @client = client
        @results = arrayize(parse_response)
      end

      private

      def arrayize(inputs)
        @arrayize ||= if inputs.is_a?(Array)
                        inputs.map do |input|
                          marshall(input)
                        end
                      else
                        marshall(inputs)
                      end
      end

      def parse_response
        @parse_response ||= if @data.is_a?(Array)
                              @data.map do |datum|
                                {
                                  response: JSON.parse(datum.response.response_body),
                                  request: datum.response.request
                                }
                              end
                            else
                              {
                                response: JSON.parse(@data.response_body),
                                request: @data.request
                              }
                            end
      end

      def marshall(input_hash)
        {
          short_url: input_hash[:response]['link'],
          long_url: input_hash[:response]['long_url'],
          user_clicks: input_hash[:response]['total_clicks']
        }
      end
    end
  end
end
