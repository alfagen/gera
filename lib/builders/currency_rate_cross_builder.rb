require_relative 'currency_rate_builder'

module Gera
  class CurrencyRateCrossBuilder < CurrencyRateBuilder
    attribute :cross_rate_modes

    private

    def build
      @cached_pairs = Set.new

      CurrencyRate.new(
        currency_pair:  currency_pair,
        rate_value:     external_rates.map(&:rate_value).inject(&:*),
        mode:           :cross,
        external_rates: external_rates
      )
    end

    def external_rates
      @external_rates ||= build_external_rates(cross_rates)
    end

    def cross_rates
      return cross_rate_modes if cross_rate_modes.present?
      generate_cross_rates currency_pair
    end

    def build_external_rates(cross_rates)
      cross_rates.map do |cr|
        if cr.rate_source.present?
          cr.rate_source.find_rate_by_currency_pair! cr.currency_pair
        else
          find_external_rate(cr.currency_pair) || raise(Error, "При расчете кросс-курса не найден источник для #{cr.currency_pair}")
        end
      end.flatten
    end

    def generate_cross_rates(pair)
      # TODO вынести в настройки или в автоматм
      if pair.include?(KZT) || pair.include?(EUR)
        cross_cur = RUB
      else
        cross_cur = USD
      end

      [
        Gera::CrossRateMode.new(currency_pair: pair.change_to(cross_cur)).freeze,
        Gera::CrossRateMode.new(currency_pair: pair.change_from(cross_cur)).freeze
      ]
    end

    def sources
      @sources ||= Gera::RateSource.enabled.ordered
    end

    def find_external_rate pair
      raise Error, "Циклический поиск (#{@cached_pairs.to_a.join(',')}) курса для #{pair}" if @cached_pairs.include? pair
      @cached_pairs << pair
      sources.each do |source|
        external_rate = source.find_rate_by_currency_pair pair
        return external_rate if external_rate.present?
      end

      build_external_rates generate_cross_rates pair
    end
  end
end
