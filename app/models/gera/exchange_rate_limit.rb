# frozen_string_literal: true

module Gera
  class ExchangeRateLimit < ApplicationRecord
    belongs_to :exchange_rate, class_name: 'Gera::ExchangeRate'
  end
end
