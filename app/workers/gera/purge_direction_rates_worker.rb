# frozen_string_literal: true

module Gera
  class PurgeDirectionRatesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :purgers, retry: false

    KEEP_PERIOD = 3.hours

    def perform
      direction_rate_snapshots.batch_purge
      direction_rates.batch_purge
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
