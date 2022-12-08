# frozen_string_literal: true

module Gera
  class CurrencyRateMode < ApplicationRecord
    include CurrencyPairSupport
    include CurrencyRateModeBuilderSupport
    include Authority::Abilities

    belongs_to :snapshot, class_name: 'CurrencyRateModeSnapshot', foreign_key: :currency_rate_mode_snapshot_id
    has_many :cross_rate_modes

    # Тут режими из ключей rate_source
    # TODO выделить привязку к rate_source в отедельную ассоциацию
    enum mode: %i[auto cbr cbr_avg exmo cross bitfinex], _prefix: true

    accepts_nested_attributes_for :cross_rate_modes, reject_if: :all_blank, allow_destroy: true

    delegate :to_s, to: :mode

    def self.default_for_pair(pair)
      new(currency_pair: pair, mode: :auto)
    end

    def to_s
      new_record? && mode.auto? ? "default" : mode
    end

    def mode
      super.inquiry
    end
  end
end
