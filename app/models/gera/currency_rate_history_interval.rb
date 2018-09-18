module Gera
  class CurrencyRateHistoryInterval < ApplicationRecord
    include HistoryIntervalConcern
    self.table_name = 'currency_rate_history_intervals'

    def self.create_by_interval!(interval_from, interval_to = nil)
      interval_to ||= interval_from + INTERVAL
      CurrencyRate.
        where('created_at >= ? and created_at < ?', interval_from, interval_to).
        group(:cur_from, :cur_to).
        pluck(:cur_from, :cur_to, 'min(rate_value)', 'max(rate_value)').
        each do |cur_from, cur_to, min_rate, max_rate|

        next if cur_from == cur_to

        create!(
          cur_from_id: Money::Currency.find(cur_from).local_id,
          cur_to_id: Money::Currency.find(cur_to).local_id,
          min_rate: min_rate, max_rate: max_rate,
          interval_from: interval_from, interval_to: interval_to
        )
      end
    end
  end
end
