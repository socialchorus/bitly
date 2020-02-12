module Bitly
  module V4
    class Referrer
      attr_reader :clicks, :referrer, :referrer_app, :url

      def initialize(opts)
        %w[clicks referrer referrer_app url].each do |attribute|
          instance_variable_set("@#{attribute}".to_sym, opts[attribute])
        end
      end
    end
  end
end
