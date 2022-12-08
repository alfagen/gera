module Gera
  class CurrencyRateBuilder
    Error = Class.new StandardError
    Result = Class.new
    class SuccessResult < Result
      include Virtus.model
      attribute :currency_rate #, CurrencyRate

      def success?
        true
      end

      def error?
        false
      end
    end

    class ErrorResult < Result
      include Virtus.model
      attribute :error, StandardError

      def currency_rate
        nil
      end

      def success?
        false
      end

      def error?
        true
      end
    end

    include Virtus.model

    attribute :currency_pair, CurrencyPair

    def build_currency_rate
      currency_rate = build
      SuccessResult.new(currency_rate: currency_rate).freeze
    rescue => error
      Rails.logger.error(error) unless error.is_a?(Error)
      ErrorResult.new(error: error).freeze
    end

    private

    def build
      raise 'not implemented'
    end
  end
end
