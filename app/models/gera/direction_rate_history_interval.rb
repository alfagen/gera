# frozen_string_literal: true

module Gera
  class DirectionRateHistoryInterval < ApplicationRecord
    include HistoryIntervalConcern

    # Их не надо подключать, потому что иначе при создании записи
    # ActiveRercord проверяет есить ли они в базе
    #
    # belongs_to :payment_system_from, class_name: 'PaymentSystem'
    # belongs_to :payment_system_to, class_name: 'PaymentSystem'

    def self.create_by_interval!(interval_from, interval_to = nil)
      interval_to ||= interval_from + INTERVAL
      DirectionRate
        .where('created_at >= ? and created_at < ?', interval_from, interval_to)
        .group(:ps_from_id, :ps_to_id)
        .pluck(:ps_from_id, :ps_to_id, 'min(rate_value)', 'max(rate_value)', 'min(rate_percent)', 'max(rate_percent)')
        .each do |ps_from_id, ps_to_id, min_rate, max_rate, min_comission, max_comission|

        next if ps_from_id == ps_to_id

        create!(
          payment_system_from_id: ps_from_id,
          payment_system_to_id: ps_to_id,
          min_rate: min_rate, max_rate: max_rate,
          min_comission: min_comission, max_comission: max_comission,
          interval_from: interval_from, interval_to: interval_to
        )
      end
    end
  end
end
