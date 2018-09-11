class Universe
  class << self
    delegate :currency_rate_modes_repository, :currency_rates_repository, :direction_rates_repository, :exchange_rates_repository,
      :payment_systems,
      :reserves,
      :clear!,
      to: :instance

    def instance
      RequestStore[:universe_repository] ||= new
    end
  end

  attr_reader :currency_rate_modes_repository, :currency_rates_repository, :direction_rates_repository

  def clear!
    @currency_rates_repository = nil
    @currency_rate_modes_repository = nil
    @direction_rates_repository = nil
    @exchange_rates_repository = nil
    @payment_systems = nil
    @reserves = nil
  end

  def reserves
    @reserves ||= ReservesByPaymentSystems.new
  end

  def payment_systems
    @payment_systems ||= PaymentSystemsRepository.new
  end

  def currency_rate_modes_repository
    @currency_rate_modes_repository ||= CurrencyRateModesRepository.new
  end

  def currency_rates_repository
    @currency_rates_repository ||= CurrencyRatesRepository.new
  end

  def direction_rates_repository
    @direction_rates_repository ||= DirectionRatesRepository.new
  end

  def exchange_rates_repository
    @exchange_rates_repository ||= ExchangeRatesRepository.new
  end
end
