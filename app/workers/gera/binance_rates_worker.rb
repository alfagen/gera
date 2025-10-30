# frozen_string_literal: true

module Gera
  class BinanceRatesWorker
    include Sidekiq::Worker
    include AutoLogger
    include RatesWorker

    sidekiq_options lock: :until_executed

    def perform
      # Check if we should approve new rates based on count
      unless should_approve_new_rates?
        logger.debug "BinanceRatesWorker: Rate counts don't match, skipping"
        return nil
      end

      super
    end

    private

    def rate_source
      @rate_source ||= RateSourceBinance.get!
    end

    def load_rates
      BinanceFetcher.new.perform
    end

    def rate_keys
      { buy: 'bidPrice', sell: 'askPrice' }
    end

    def should_approve_new_rates?
      # Always approve if no current snapshot
      return true unless rate_source.actual_snapshot_id

      current_rates_count = rate_source.actual_snapshot.external_rates.count
      new_rates_count = load_rates.size

      logger.info "BinanceRatesWorker: current_rates_count=#{current_rates_count}, new_rates_count=#{new_rates_count}"

      # Only approve if counts match
      current_rates_count == new_rates_count
    end
  end
end
