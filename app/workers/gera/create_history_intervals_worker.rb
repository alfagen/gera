module GERA
  class CreateHistoryIntervalsWorker
    include Sidekiq::Worker
    include AutoLogger

    MAXIMAL_DATE = 30.minutes
    MINIMAL_DATE = Time.parse('13-07-2018 18:00')

    def perform
      save_direction_rate_history_intervals
      save_currency_rate_history_intervals
    end

    private

    def lock_timeout
      1.hours * 1000
    end

    def save_direction_rate_history_intervals
      last_saved_interval = DirectionRateHistoryInterval.maximum(:interval_to)

      from = last_saved_interval || MINIMAL_DATE
      logger.info "start save_direction_rate_history_intervals from #{from}"
      DirectionRateHistoryInterval.create_multiple_intervals_from! from, MAXIMAL_DATE.ago
    end

    def save_currency_rate_history_intervals
      last_saved_interval = CurrencyRateHistoryInterval.maximum(:interval_to)

      from = last_saved_interval || MINIMAL_DATE
      logger.info "start save_currency_rate_history_intervals from #{from}"
      CurrencyRateHistoryInterval.create_multiple_intervals_from! from, MAXIMAL_DATE.ago
    end
  end
end
