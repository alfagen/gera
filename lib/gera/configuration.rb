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
    mattr_accessor :cross_pairs
    # В данном примере курс к KZT считать через RUB
    @@cross_pairs = { kzt: :rub }

    def cross_pairs
      h = {}
      @@cross_pairs.each do |k, v|
        h[Money::Currency.find!(k)] = Money::Currency.find! v
      end
      h
    end
	end
end

# Пример:
# https://github.com/RubyMoney/money-rails/blob/master/lib/money-rails/configuration.rb
