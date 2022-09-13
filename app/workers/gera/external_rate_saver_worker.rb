# frozen_string_literal: true

module Gera
  class ExternalRateSaverWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :external_rates
    RATE_ATTRIBUTES = ['sell_price', 'buy_price', 'rate_value']

    def perform(currency_pair, candidate_snapshot_id, rate)
      rate_source = find_rate_source(rate)
      candidate_snapshot = ExternalRateSnapshot.find(candidate_snapshot_id)
      create_external_rate(rate_source: rate_source, snapshot: candidate_snapshot, currency_pair: CurrencyPair.new(currency_pair), rate: rate)
      update_actual_snapshot_if_candidate_filled_up(rate_source: rate_source, candidate_snapshot: candidate_snapshot)
    rescue ActiveRecord::RecordNotUnique => err
      raise err if Rails.env.test?
    end

    private

    def find_rate_source(rate)
      rate['source_class_name'].constantize.find(rate['source_id'])
    end

    def create_external_rate(rate_source:, snapshot:, currency_pair:, rate:)
      ExternalRate.create!(
        currency_pair: currency_pair,
        snapshot: snapshot,
        source: rate_source,
        **rate.slice(*RATE_ATTRIBUTES)
      )
    end

    def update_actual_snapshot_if_candidate_filled_up(rate_source:, candidate_snapshot:)
      return unless candidate_snapshot_filled_up?(actual_snapshot: rate_source.actual_snapshot, candidate_snapshot: candidate_snapshot)

      set_candidate_snapshot_as_actual(candidate_snapshot_id: candidate_snapshot.id, rate_source: rate_source)
      update_currency_rates
    end

    def candidate_snapshot_filled_up?(actual_snapshot:, candidate_snapshot:)
      actual_snapshot.external_rates.count == candidate_snapshot.external_rates.count
    end

    def set_candidate_snapshot_as_actual(candidate_snapshot_id:, rate_source:)
      rate_source.update!(actual_snapshot_id: candidate_snapshot_id)
    end

    def update_currency_rates
      CurrencyRatesWorker.perform_async
    end
  end
end
