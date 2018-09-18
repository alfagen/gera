module Gera
  module CurrencyPairGenerator
    def generate_pairs_from_currencies(currencies)
      currencies = currencies.map { |c| Money::Currency.find c }

      currencies.
        map { |c1| currencies.reject { |c2| c2==c1 }.map { |c2| [c1,c2].join('/') } }.
        flatten.compact.
        map { |cp| Gera::CurrencyPair.new cp }.uniq
    end
  end
end
