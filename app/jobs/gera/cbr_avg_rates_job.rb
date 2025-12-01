# frozen_string_literal: true

module Gera
  class CbrAvgRatesJob < ApplicationJob
    include AutoLogger

    limits_concurrency to: 1, key: -> { 'gera_cbr_avg_rates' }, duration: 1.minute

    def perform
      ActiveRecord::Base.connection.clear_query_cache
      ActiveRecord::Base.transaction do
        source.available_pairs.each do |pair|
          create_rate pair
        end
      end
      source.update_column :actual_snapshot_id, snapshot.id
    end

    private

    def source
      @source ||= Gera::RateSourceCbrAvg.get!
    end

    def snapshot
      @snapshot ||= source.snapshots.create!
    end

    def create_rate(pair)
      er = Gera::RateSource.cbr.find_rate_by_currency_pair pair

      price = (er.sell_price + er.buy_price) / 2.0

      Gera::ExternalRate.create!(
        source: source,
        snapshot: snapshot,
        currency_pair: pair,
        sell_price: price,
        buy_price: price
      )
    end
  end
end
