module Gera
  class DirectionRatesRepository
    FinitRateNotFound = Class.new StandardError
    NoActualSnapshot = Class.new StandardError

    def snapshot
      @snapshot ||= DirectionRateSnapshot.last || raise(NoActualSnapshot, "No actual DirectionRate snapshot")
    end

    def all
      snapshot.direction_rates
    end

    def find_direction_rate_by_exchange_rate_id er_id
      rates_by_exchange_rate_id[er_id] || raise(FinitRateNotFound, "No DirectionRate for exchange_rate_id=#{er_id} in direction_rate_snapshot_id=#{snapshot.id}")
    end

    def find_by_direction direction
      get_by_direction direction
    end

    def get_by_direction direction
      get_matrix.fetch(direction.ps_from_id, {}).fetch(direction.ps_to_id, nil)
    end

    def get_matrix
      @matrix ||= build_matrix
    end

    private

    def build_matrix
      hash = {}
      snapshot.direction_rates.each do |dr|
        hash[dr.ps_from_id] ||= {}
        hash[dr.ps_from_id][dr.ps_to_id] = dr
      end

      hash
    end

    def rates_by_exchange_rate_id
      @rates_by_exchange_rate_id ||= snapshot.direction_rates.each_with_object({}) { |dr, h| h[dr.exchange_rate_id]=dr }
    end
  end
end
