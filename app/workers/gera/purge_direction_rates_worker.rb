# frozen_string_literal: true

module Gera
  class PurgeDirectionRatesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :purgers, retry: false

    KEEP_PERIOD = 3.hours

    def perform
      direction_rate_snapshots.batch_purge

      # Удаляем отдельно, потому что они могут жить отдельно и связываются
      # с direction_rate_snapshot через кросс-таблицу
      direction_rates.batch_purge

      # TODO: Тут не плохо было бы добить direction_rates которые не входят в snapshot-ы и в actual
    end

    private

    def lock_timeout
      7.days * 1000
    end

    def direction_rate_snapshots
      DirectionRateSnapshot.where.not(id: DirectionRateSnapshot.last).where('created_at < ?', KEEP_PERIOD.ago)
    end

    def direction_rates
      DirectionRate.where.not(id: DirectionRateSnapshot.last.direction_rates.pluck(:id)).where('created_at < ?', KEEP_PERIOD.ago)
    end
  end
end
