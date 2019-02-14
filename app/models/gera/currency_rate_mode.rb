# frozen_string_literal: true

module Gera
  class CurrencyRateMode < ApplicationRecord
    include CurrencyPairSupport
    include CurrencyRateModeBuilderSupport
    include Authority::Abilities

    self.table_name = 'currency_rate_modes'

    belongs_to :snapshot, class_name: 'CurrencyRateModeSnapshot', foreign_key: :currency_rate_mode_snapshot_id
    has_many :cross_rate_modes

    # Тут режими из ключей rate_source
    # TODO выделить привязку к rate_source в отедельную ассоциацию
    enum mode: %i[auto cbr cbr_avg exmo cross bitfinex], _prefix: true

    accepts_nested_attributes_for :cross_rate_modes, reject_if: :all_blank, allow_destroy: true

    delegate :to_s, to: :mode
  end
end
