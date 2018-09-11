module GERA
  class CrossRateMode < ApplicationRecord
    include CurrencyPairSupport
    self.table_name = 'cross_rate_modes'

    belongs_to :currency_rate_mode
    belongs_to :rate_source, optional: true

    def title
      "#{currency_pair}(#{rate_source || 'auto'})"
    end
  end
end
