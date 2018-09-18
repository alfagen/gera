module Gera
  module Numeric
    def to_rate
      RateFromMultiplicator.new(self)
    end

    def percents
      self.to_percent
    end

    # 10.percent_of(100)  # => (10/1)
    def percent_of(value)
      value * to_percent
    end

    # 5.as_percentage_of(10)  # => 50.0%
    def as_percentage_of(value)
      (self.to_f * 100.0 / value).to_percent
    end
  end
end

class ::Numeric
  include Gera::Numeric
end
