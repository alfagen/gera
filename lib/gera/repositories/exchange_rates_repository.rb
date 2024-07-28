module Gera
  class ExchangeRatesRepository
    def find_by_direction direction
      get_matrix[direction.ps_from_id][direction.ps_to_id]
    end

    def get_matrix
      @matrix ||= build_matrix
    end

    private

    def build_matrix
      hash = {}
      Gera::ExchangeRate.all.each do |er|
        hash[er.ps_from_id] ||= {}
        hash[er.ps_from_id][er.ps_to_id] = er
      end

      hash
    end
  end
end
