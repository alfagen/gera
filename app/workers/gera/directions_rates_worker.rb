module Gera
  class DirectionsRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    Error = Class.new StandardError

    sidekiq_options queue: :critical

    # exchange_rate_id - ID изменившегося направление
    # фактически не используется
    #
    def perform(*args) # exchange_rate_id: nil)
      logger.info "start"

      DirectionRate.transaction do
        # Генерруем для всех, потому что так нужно старому пыху
        # ExchangeRate.available.find_each do |er|
        ExchangeRate.includes(:payment_system_from, :payment_system_to).find_each do |er|
          safe_create er
        end
      end
      logger.info "finish"
    end

    private

    delegate :direction_rates, to: :snapshot

    def snapshot
      @snapshot ||= DirectionRateSnapshot.create!
    end

    def safe_create exchange_rate
      direction_rates.create!(
        exchange_rate: exchange_rate,
        currency_rate: Universe.currency_rates_repository.find_currency_rate_by_pair(exchange_rate.currency_pair)
      )

    rescue DirectionRate::UnknownExchangeRate, ActiveRecord::RecordInvalid, CurrencyRatesRepository::UnknownPair => err
      logger.error err
      Bugsnag.notify err do |b|
        b.meta_data = { exchange_rate_id: exchange_rate.id, currency_rate_id: currency_rate.try(:id) }
      end
    end
  end
end
