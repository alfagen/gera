class CurrencyRateBuilder
  Error = Class.new StandardError
  class Result
    include Virtus.model

    attribute :currency_rate #, CurrencyRate
    attribute :error, StandardError

    def success?
      ! error?
    end

    def error?
      error.present?
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

  def success(currency_rate)
    Result.new(currency_rate: currency_rate).freeze
  end

  def failure(error)
    Result.new(error: error).freeze
  end
end
