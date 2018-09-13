module GERA
  class CbrExternalRate < ApplicationRecord
    self.table_name = 'cbr_external_rates'

    before_save do
      raise 'нет значения' unless rate > 0
    end

    def <=>(other)
      rate <=> other.rate
    end
  end
end
