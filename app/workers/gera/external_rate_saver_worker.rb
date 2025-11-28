# frozen_string_literal: true

module Gera
  class ExternalRateSaverWorker
    include Sidekiq::Worker
    include AutoLogger

    sidekiq_options queue: :external_rates

    def perform(currency_pair, snapshot_id, rate, source_rates_count)
      rate_source = find_rate_source(rate)
      snapshot = Gera::ExternalRateSnapshot.find(snapshot_id)
      create_external_rate(
        rate_source: rate_source,
        snapshot: snapshot,
        currency_pair: Gera::CurrencyPair.new(currency_pair),
        rate_value: rate['value']
      )
      update_actual_snapshot(
        rate_source: rate_source,
        snapshot: snapshot,
      ) if snapshot_filled_up?(snapshot: snapshot, source_rates_count: source_rates_count)
    rescue ActiveRecord::RecordNotUnique => err
      raise err if Rails.env.test?
    end

    private

    def find_rate_source(rate)
      rate['source_class_name'].constantize.find(rate['source_id'])
    end

    def create_external_rate(rate_source:, snapshot:, currency_pair:, rate_value:)
      Gera::ExternalRate.create!(
        currency_pair: currency_pair,
        snapshot: snapshot,
        source: rate_source,
        rate_value: rate_value
      )
    end

    def update_actual_snapshot(rate_source:, snapshot:)
      update_actual_snapshot(snapshot: snapshot, rate_source: rate_source)
    end

    def snapshot_filled_up?(snapshot:, source_rates_count:)
      snapshot.external_rates.count == source_rates_count * 2
    end

    def update_actual_snapshot(snapshot:, rate_source:)
      rate_source.update!(actual_snapshot_id: snapshot.id)
    end
  end
end
