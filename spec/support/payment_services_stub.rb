# frozen_string_literal: true

# Stub for PaymentServices::Base::Client which is missing in this project
# See: https://github.com/alfagen/gera/issues/78
module PaymentServices
  module Base
    class Client
      def http_request(url:, method:, body: nil, headers: {})
        ''
      end

      def safely_parse(response)
        JSON.parse(response)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
