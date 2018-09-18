module Gera
  class PaymentSystemsRepository
    def find_by_id id
      cache_by_id[id]
    end

    def available
      @available ||= PaymentSystem.available.ordered.load
    end

    def all
      @all ||= PaymentSystem.ordered.load
    end

    private

    def cache_by_id
      @cache_by_id ||= PaymentSystem.ordered.load.each_with_object({}) { |ps, h| h[ps.id] = ps }
    end
  end
end
