# frozen_string_literal: true

module Gera
  class ExternalRatesBatchJob < ApplicationJob
    queue_as :default

    def perform(snapshot_id, rate_source_id, rates)
      snapshot = Gera::ExternalRateSnapshot.find(snapshot_id)
      rate_source = Gera::RateSource.find(rate_source_id)

      values = rates.flat_map do |pair, prices|
        cur_from, cur_to = pair.split('/')

        buy  = prices[:buy]  || prices['buy']
        sell = prices[:sell] || prices['sell']

        next if buy.nil? || sell.nil?

        buy  = buy.to_f
        sell = sell.to_f
        next if buy <= 0 || sell <= 0

        [
          {
            snapshot_id: snapshot.id,
            source_id: rate_source.id,
            cur_from: cur_from,
            cur_to: cur_to,
            rate_value: buy
          },
          {
            snapshot_id: snapshot.id,
            source_id: rate_source.id,
            cur_from: cur_to,
            cur_to: cur_from,
            rate_value: (1.0 / sell)
          }
        ]
      end.compact

      Gera::ExternalRate.insert_all(values) if values.any?
      rate_source.update!(actual_snapshot_id: snapshot.id)
    end
  end
end
