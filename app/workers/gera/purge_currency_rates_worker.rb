# frozen_string_literal: true

module Gera
  class PurgeCurrencyRatesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :purgers, retry: false

    KEEP_PERIOD = 3.hours

    def perform
      # Удаляем меньшими пачками, потому что каскадом удаляются прямая зависимость (currency_rates)
      currency_rate_snapshots.batch_purge batch_size: 100
    end

    private

    def currency_rate_snapshots
      CurrencyRateSnapshot.where.not(id: CurrencyRateSnapshot.last).where('created_at < ?', KEEP_PERIOD.ago)
    end
  end
end
