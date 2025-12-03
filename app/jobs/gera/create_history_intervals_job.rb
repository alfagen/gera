# frozen_string_literal: true

module Gera
  class CreateHistoryIntervalsJob < ApplicationJob
    include AutoLogger

    limits_concurrency to: 1, key: ->(_job) { 'gera_create_history_intervals' }, duration: 1.hour

    MAXIMAL_DATE = 30.minutes
    MINIMAL_DATE = Time.parse('13-07-2018 18:00')

    def perform
      save_direction_rate_history_intervals if Gera::DirectionRateHistoryInterval.table_exists?
      save_currency_rate_history_intervals if Gera::CurrencyRateHistoryInterval.table_exists?
    end

    private

    def save_direction_rate_history_intervals
      last_saved_interval = Gera::DirectionRateHistoryInterval.maximum(:interval_to)

      from = last_saved_interval || MINIMAL_DATE
      logger.info "start save_direction_rate_history_intervals from #{from}"
      Gera::DirectionRateHistoryInterval.create_multiple_intervals_from! from, MAXIMAL_DATE.ago
    end

    def save_currency_rate_history_intervals
      last_saved_interval = Gera::CurrencyRateHistoryInterval.maximum(:interval_to)

      from = last_saved_interval || MINIMAL_DATE
      logger.info "start save_currency_rate_history_intervals from #{from}"
      Gera::CurrencyRateHistoryInterval.create_multiple_intervals_from! from, MAXIMAL_DATE.ago
    end
  end
end
