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
                                  response: json_parse(datum[:request].response.response_body),
                                  request: datum[:metadata]
                                }
                              end
                            else
                              {
                                response: json_parse(@data[:request].response_body),
                                request: @data[:metadata]
                              }
                            end
      end

      def marshall(input_hash)
        response = input_hash[:response]
        request = input_hash[:request]

        {
          short_url: response['link'] || request[:short_url],
          long_url: response['long_url'] || request[:long_url],
          user_clicks: response['total_clicks'],
          error: response['message'],
          code: response['code']
        }.reject { |_, value| value.nil? || value.to_s.empty? }
      end

      def json_parse(input)
        JSON.parse(input)
      rescue JSON::ParserError
        { 'message' => 'unexpected error' }
      end
    end
  end
end
