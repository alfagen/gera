# Банк для Money
#

module Gera
  class CurrencyExchange
    def self.get_rate(cur_from, cur_to)
      pair = CurrencyPair.new(cur_from, cur_to)
      cr = Universe.currency_rates_repository.find_currency_rate_by_pair(pair) || raise("Отсутсвует текущий курс для #{pair}")
      cr.rate_value
    end
  end
end
