# frozen_string_literal: true

module Gera
  class ExternalRateSaverWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :external_rates

    def perform(currency_pair:, candidate_snapshot_id:, rate_source_class_name:, rate_source_id:, rate_value:)
      rate_source = rate_source_class_name.constantize.find(rate_source_id)
      candidate_snapshot = ExternalRateSnapshot.find(candidate_snapshot_id)
      ExternalRate.create!(
        currency_pair: CurrencyPair.new(currency_pair),
        snapshot: candidate_snapshot,
        source: rate_source,
        rate_value: rate_value
      )
      if candidate_snapshot_filled_up?(actual_snapshot: rate_source.actual_snapshot, candidate_snapshot: candidate_snapshot)
        set_candidate_snapshot_as_actual(candidate_snapshot_id: candidate_snapshot.id, rate_source: rate_source)
        update_currency_rates
      end
    rescue ActiveRecord::RecordNotUnique => err
      raise error if Rails.env.test?

      error_message = "save_rate_for_date: #{actual_for} , #{currency_pair} -> #{err}"
      if err.message.include? 'external_rates_unique_index'
        logger.debug error_message
        Bugsnag.notify 'Try to rewrite rates' do |b|
          b.meta_data = { actual_for: actual_for, snapshot_id: snapshot.id, currency_pair: currency_pair }
        end
      else
        logger.error error_message
        raise error
      end
    end

    private

    def candidate_snapshot_filled_up?(actual_snapshot:, candidate_snapshot:)
      actual_snapshot.external_rates.count == candidate_snapshot.external_rates.count
    end

    def set_candidate_snapshot_as_actual(candidate_snapshot_id:, rate_source:)
      rate_source.update!(actual_snapshot_id: candidate_snapshot_id)
    end

    def update_currency_rates
      CurrencyRatesWorker.new.perform_async
    end
  end
end
