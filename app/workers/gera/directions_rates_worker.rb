# frozen_string_literal: true

module Gera
  class DirectionsRatesWorker
    include ActiveSupport::Callbacks
    include Sidekiq::Worker
    include AutoLogger

    Error = Class.new StandardError

    sidekiq_options queue: :critical, lock: :until_executed
    define_callbacks :perform

    # exchange_rate_id - ID of changes exchange_rate
    #
    def perform(*_args) # exchange_rate_id: nil)
      logger.info 'start'

      run_callbacks :perform do
        DirectionRateSnapshot.transaction do
          rates = ExchangeRate.includes(:target_autorate_setting, payment_system_from: { auto_rate_settings: :auto_rate_checkpoints }, payment_system_to: { auto_rate_settings: :auto_rate_checkpoints }).map do |exchange_rate|
            rate_value = Universe.currency_rates_repository.find_currency_rate_by_pair(exchange_rate.currency_pair)

            next unless rate_value

            base_rate_value = rate_value.rate_value
            rate_percent = exchange_rate.final_rate_percents
            current_time = Time.current
            {
              ps_from_id: exchange_rate.payment_system_from_id,
              ps_to_id: exchange_rate.payment_system_to_id,
              snapshot_id: snapshot.id,
              exchange_rate_id: exchange_rate.id,
              currency_rate_id: rate_value.id,
              created_at: current_time,
              base_rate_value: base_rate_value,
              rate_percent: rate_percent,
              rate_value: calculate_finite_rate(base_rate_value, rate_percent)
            }
            rescue CurrencyRatesRepository::UnknownPair, DirectionRate::UnknownExchangeRate
              nil
          end.compact

          DirectionRate.insert_all(rates)
        end
      end
      logger.info 'finish'
    end

    private

    delegate :direction_rates, to: :snapshot

    def snapshot
      @snapshot ||= Gera::DirectionRateSnapshot.create!
    end

    def calculate_finite_rate(base_rate, comission)
      if base_rate <= 1
        base_rate.to_f * (1.0 - comission.to_f/100)
      else
        base_rate - comission.to_percent
      end
    end
  end
end
