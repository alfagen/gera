# frozen_string_literal: true

module Gera
  #
  # Build currency rates on base of imported rates and calculation modes
  #
  class CurrencyRatesJob < ApplicationJob
    include AutoLogger

    queue_as :default

    def perform
      logger.info 'start'
      Gera::CurrencyRate.transaction do
        snapshot = create_snapshot
        Gera::CurrencyPair.all.each { |pair| create_rate(pair: pair, snapshot: snapshot) }
      end
      logger.info 'finish'
      Gera::DirectionsRatesJob.perform_later
      true
    end

    private

    def create_snapshot
      Gera::CurrencyRateSnapshot.create!(currency_rate_mode_snapshot: currency_rates.snapshot)
    end

    def currency_rates
      Gera::Universe.currency_rate_modes_repository
    end

    def create_rate(pair:, snapshot:)
      currency_rate_mode = find_currency_rate_mode_by_pair(pair)
      logger.debug "build_rate(#{pair}, #{currency_rate_mode})"
      currency_rate = currency_rate_mode.build_currency_rate

      unless currency_rate.present?
        logger.warn "Unable to calculate rate for #{pair} and mode '#{currency_rate_mode.mode}'"
        return
      end

      currency_rate.snapshot = snapshot
      currency_rate.save!
    rescue Gera::RateSource::RateNotFound => err
      logger.warn err
    rescue StandardError => err
      raise err if Rails.env.test?

      logger.error err
      Bugsnag.notify(err) { |b| b.meta_data = { pair: pair } } if defined? Bugsnag
    end

    def find_currency_rate_mode_by_pair(pair)
      currency_rates.find_currency_rate_mode_by_pair(pair) ||
        Gera::CurrencyRateMode.default_for_pair(pair).freeze
    end
  end
end
