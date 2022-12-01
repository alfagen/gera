# frozen_string_literal: true

module Gera
  class ExternalRateSaverWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :external_rates

    def perform(currency_pair, candidate_snapshot_id, rate, total_rates_count)
      rate_source = find_rate_source(rate)
      candidate_snapshot = ExternalRateSnapshot.find(candidate_snapshot_id)
      create_external_rate(
        rate_source: rate_source,
        snapshot: candidate_snapshot,
        currency_pair: CurrencyPair.new(currency_pair),
        rate_value: rate['value']
      )
      update_actual_snapshot_if_candidate_filled_up(
        rate_source: rate_source,
        candidate_snapshot: candidate_snapshot,
        total_rates_count: total_rates_count
      )
    rescue ActiveRecord::RecordNotUnique => err
      raise err if Rails.env.test?
    end

    private

    def find_rate_source(rate)
      rate['source_class_name'].constantize.find(rate['source_id'])
    end

    def create_external_rate(rate_source:, snapshot:, currency_pair:, rate_value:)
      ExternalRate.create!(
        currency_pair: currency_pair,
        snapshot: snapshot,
        source: rate_source,
        rate_value: rate_value
      )
    end

    def update_actual_snapshot_if_candidate_filled_up(rate_source:, candidate_snapshot:, total_rates_count:)
      return unless snapshot_filled_up?(snapshot: candidate_snapshot, total_rates_count: total_rates_count)

      update_actual_snapshot(snapshot: candidate_snapshot, rate_source: rate_source)
      update_currency_rates
    end

    def snapshot_filled_up?(snapshot:, total_rates_count:)
      snapshot.external_rates.count == total_rates_count
    end

    def set_candidate_snapshot_as_actual(snapshot:, rate_source:)
      rate_source.update!(actual_snapshot_id: snapshot.id)
    end

    def update_currency_rates
      CurrencyRatesWorker.perform_async
    end
  end
end
