module Gera
	# Gera configuration module.
	# This is extended by Gera to provide configuration settings.
	module Configuration

		# Start a Gera configuration block in an initializer.
		#
		# example: Provide a default currency for the application
		#   Gera.configure do |config|
		#     config.default_currency = :eur
		#   end
		def configure
			yield self
		end

    # @param [Class] Декоратор для PaymentSystem
    mattr_accessor :payment_system_decorator
    def payment_system_decorator
      @@payment_system_decorator || PaymentSystemDecorator
    end

    # @param [Symbol] Валюта для кросс-расчетов по-умолчанию
    mattr_accessor :default_cross_currency
    @@default_cross_currency = :usd

    def default_cross_currency
      return @@default_cross_currency if @@default_cross_currency.is_a? Money::Currency
      Money::Currency.find! @@default_cross_currency
    end

    # @param [Hash] Набор кросс-валют для расчета
    # @param [Object] HTTP клиент для работы с Manul API (BestChange rates fetcher)
    mattr_accessor :cross_pairs, :manul_client
    # В данном примере курс к KZT считать через RUB
    @@cross_pairs = { kzt: :rub }
    @@manul_client = nil

    # @param [Boolean] Включение/отключение создания direction_rate_history_intervals
    # По умолчанию true для обратной совместимости
    # Таблица занимает ~42GB и используется только для графиков в админке
    mattr_accessor :enable_direction_rate_history_intervals
    @@enable_direction_rate_history_intervals = true

    def cross_pairs
      h = {}
      @@cross_pairs.each do |k, v|
        h[Money::Currency.find!(k)] = Money::Currency.find! v
      end
      h
    end

    # @param [Integer] ID нашего обменника в BestChange (для исключения из расчёта позиции)
    mattr_accessor :our_exchanger_id
    @@our_exchanger_id = nil

    # @param [Float] Порог аномальной комиссии для защиты от манипуляторов (UC-9)
    # Если комиссия отличается от медианы более чем на этот процент - считается аномальной
    mattr_accessor :anomaly_threshold_percent
    @@anomaly_threshold_percent = 50.0
	end
end

# Пример:
# https://github.com/RubyMoney/money-rails/blob/master/lib/money-rails/configuration.rb
