# frozen_string_literal: true

module Gera
  class CrossRateMode < ApplicationRecord
    include CurrencyPairSupport
    belongs_to :currency_rate_mode
    belongs_to :rate_source, optional: true

    def title
      "#{currency_pair}(#{rate_source || 'auto'})"
    end
  end
end
