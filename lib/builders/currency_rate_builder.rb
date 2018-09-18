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
      success build
    rescue => err
      Rails.logger.error err unless err.is_a? Error
      failure err
    end

    private

    def build
      raise 'not implemented'
    end

    def success(currency_rate)
      SuccessResult.new(currency_rate: currency_rate).freeze
    end

    def failure(error)
      ErrorResult.new(error: error).freeze
    end
  end
end
