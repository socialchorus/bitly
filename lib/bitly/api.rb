# frozen_string_literal: true

module Bitly
  module API
    BASE_URL = URI("https://api-ssl.bitly.com/v4")
  end
end

require_relative './api/client'
require_relative './api/organization'
require_relative './api/group'