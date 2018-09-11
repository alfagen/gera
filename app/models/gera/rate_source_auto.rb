module GERA
  class RateSourceAuto < RateSource
    def build_currency_rate(pair)
      build_same(pair) ||
        build_from_source(manual, pair) ||
        build_from_source(cbr, pair) ||
        build_from_source(exmo, pair) ||
        build_cross(pair)
    end

    private

    def build_from_source source, pair, allow_inverse = true
      source.build_currency_rate pair, allow_inverse
    end

    def build_same(pair)
      return unless pair.same?
      CurrencyRate.new currency_pair: pair, rate_value: 1, mode: :same
    end
  end
end
