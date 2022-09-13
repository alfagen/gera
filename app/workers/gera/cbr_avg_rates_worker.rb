# frozen_string_literal: true

module Gera
  class CBRAvgRatesWorker
    include Sidekiq::Worker
    include AutoLogger

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
      @source ||= RateSourceCBRAvg.get!
    end

    def snapshot
      @snapshot ||= source.snapshots.create!
    end

    def create_rate(pair)
      er = RateSource.cbr.find_rate_by_currency_pair pair

      price = (er.sell_price + er.buy_price) / 2.0

      rate = { source_class_name: source.class.name, source_id: source.id, sell_price: price, buy_price: price }
      ExternalRateSaverWorker.perform_async(pair, snapshot.id, rate)
    end
  end
end
