# frozen_string_literal: true

module Gera
  #
  # Build currency rates on base of imported rates and calculation modes
  #
  class CurrencyRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    Error = Class.new StandardError

    def perform
      logger.info 'start'
      CurrencyRate.transaction do
        snapshot = create_snapshot
        CurrencyPair.all.each { |pair| create_rate(pair: pair, snapshot: snapshot) }
      end
      logger.info 'finish'
      DirectionsRatesWorker.perform_async
      true
    end

    private

    def create_snapshot
      CurrencyRateSnapshot.create!(currency_rate_mode_snapshot: currency_rates.snapshot)
    end

    def currency_rates
      Universe.currency_rate_modes_repository
    end

    def create_rate(pair:, snapshot:)
      currency_rate_mode = find_currency_rate_mode_by_pair(pair)
      logger.debug "build_rate(#{pair}, #{currency_rate_mode})"
      currency_rate = currency_rate_mode.build_currency_rate
      raise Error, "Unable to calculate rate for #{pair} and mode '#{currency_rate_mode.mode}'" unless currency_rate.present?

      currency_rate.snapshot = snapshot
      currency_rate.save!
    rescue RateSource::RateNotFound => err
      logger.error err
    rescue StandardError => err
      raise err if !err.is_a?(Error) && Rails.env.test?
      logger.error err

      if defined? Bugsnag
        Bugsnag.notify err do |b|
          b.meta_data = { pair: pair }
        end
      end
    end

    def find_currency_rate_mode_by_pair(pair)
      currency_rates.find_currency_rate_mode_by_pair(pair) ||
        CurrencyRateMode.default_for_pair(pair).freeze
    end
  end
end
