# frozen_string_literal: true

module Gera
  class DirectionsRatesWorker
    include ActiveSupport::Callbacks
    include Sidekiq::Worker
    include AutoLogger

    Error = Class.new StandardError

    sidekiq_options queue: :critical, lock: :while_executing
    define_callbacks :perform

    # exchange_rate_id - ID of changes exchange_rate
    #
    def perform(*_args) # exchange_rate_id: nil)
      logger.info 'start'


      run_callbacks :perform do
        DirectionRate.transaction do
          ExchangeRate.includes(:payment_system_from, :payment_system_to).find_each do |exchange_rate|
            safe_create(exchange_rate)
          end
        end
      end
      logger.info 'finish'
    end

    private

    delegate :direction_rates, to: :snapshot

    def snapshot
      @snapshot ||= DirectionRateSnapshot.create!
    end

    def safe_create(exchange_rate)
      direction_rates.create!(
        snapshot: snapshot,
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
