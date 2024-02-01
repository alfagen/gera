# frozen_string_literal: true

module Gera
  class TargetAutorateSetting < ApplicationRecord
    belongs_to :exchange_rate, class_name: 'Gera::ExchangeRate'

    def could_be_calculated?
      position_from.present? && position_to.present? && autorate_from.present? && autorate_to.present?
    end
  end
end
