module GERA
  class CbrExternalRate < ApplicationRecord
    before_save do
      raise 'нет значения' unless rate > 0
    end

    def <=>(other)
      rate <=> other.rate
    end
  end
end
