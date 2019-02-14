# frozen_string_literal: true

module Gera
  class CBRAvgRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    def perform
      ActiveRecord::Base.connection.clear_query_cache
      source.with_lock do
        source.available_pairs.each do |pair|
          create_rate pair
        end
        source.update_attribute :actual_snapshot_id, snapshot.id
      end
    end

    private

    def source
      @source ||= RateSourceCBRAvg.get!
    end

    def snapshot
      @snapshot ||= source.snapshots.create!
    end

    def create_rate(pair)
      er = RateSource.cbr.find_rate_by_currency_pair pair

      price = (er.sell_price + er.buy_price) / 2.0

      ExternalRate.create!(
        source: source,
        snapshot: snapshot,
        currency_pair: pair,
        sell_price: price,
        buy_price: price
      )
    end
  end
end
