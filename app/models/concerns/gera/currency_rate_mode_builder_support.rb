# frozen_string_literal: true

module Gera
  module CurrencyRateModeBuilderSupport
    def build_currency_rate
      @currency_rate ||= build_currency_rate!
    rescue CurrencyRateBuilder::Error => e
      Rails.logger.warn "[CurrencyRateModeBuilderSupport] Failed to build currency rate: #{e.message}"
      nil
    end

    def build_result
      @result ||= builder.build_currency_rate
    end

    def build_currency_rate!
      raise build_result.error if build_result.error?

      build_result.currency_rate
    end

    def builder
      case mode
      when 'auto'
        CurrencyRateAutoBuilder.new(currency_pair: currency_pair)
      when 'cross'
        CurrencyRateCrossBuilder.new(currency_pair: currency_pair, cross_rate_modes: cross_rate_modes)
      else
        source = RateSource.find_by_key(mode)
        raise "not supported mode #{mode} for #{currency_pair}" unless source.present?

        CurrencyRateDirectBuilder.new currency_pair: currency_pair, source: source
      end
    end
  end
end
