# frozen_string_literal: true

module Gera
  class DirectionsRatesJob < ApplicationJob
    include ActiveSupport::Callbacks
    include AutoLogger
    include Mathematic

    Error = Class.new StandardError

    queue_as :critical
    limits_concurrency to: 1, key: ->(*) { 'gera_directions_rates' }, duration: 5.minutes

    define_callbacks :perform

    # exchange_rate_id - ID of changes exchange_rate
    #
    def perform(*_args) # exchange_rate_id: nil)
      logger.info 'start'

      run_callbacks :perform do
        Gera::DirectionRateSnapshot.transaction do
          records = build_direction_rate_records
          Gera::DirectionRate.insert_all!(records) if records.any?
        end
      end
      logger.info 'finish'
    end

    private

    def snapshot
      @snapshot ||= Gera::DirectionRateSnapshot.create!
    end

    def currency_rates_cache
      @currency_rates_cache ||= Gera::Universe.currency_rates_repository
                                              .snapshot
                                              .rates
                                              .index_by(&:currency_pair)
    end

    def build_direction_rate_records
      current_time = Time.current
      exchange_rates = Gera::ExchangeRate.includes(:payment_system_from, :payment_system_to).to_a

      exchange_rates.filter_map do |exchange_rate|
        build_direction_rate_hash(exchange_rate, current_time)
      end
    end

    def build_direction_rate_hash(exchange_rate, current_time)
      currency_rate = currency_rates_cache[exchange_rate.currency_pair]
      return nil unless currency_rate

      rate_percent = exchange_rate.final_rate_percents
      return nil if rate_percent.nil?

      base_rate_value = currency_rate.rate_value
      rate_value = calculate_finite_rate(base_rate_value, rate_percent)

      {
        snapshot_id: snapshot.id,
        exchange_rate_id: exchange_rate.id,
        currency_rate_id: currency_rate.id,
        ps_from_id: exchange_rate.income_payment_system_id,
        ps_to_id: exchange_rate.outcome_payment_system_id,
        base_rate_value: base_rate_value,
        rate_percent: rate_percent,
        rate_value: rate_value,
        created_at: current_time
      }
    rescue StandardError => e
      logger.error "Failed to build direction rate for exchange_rate #{exchange_rate.id}: #{e.message}"
      nil
    end
  end
end
