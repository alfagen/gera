module Gera
  class RateFromMultiplicator
    include Mathematic
    attr_reader :value

    delegate :+, :-, :/, :*, :==, :>, :<, :<=, :>=, to: :to_d

    delegate :to_d, :to_f, to: :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      value == other.value
    end

    def in_amount
      value > 1 ? 1.0 : 1.0 / value
    end

    def out_amount
      value > 1 ? value : 1.0
    end

    def exchange(amount, currency)
      money_exchange to_d, amount, currency
    end

    def reverse_exchange(amount, currency)
      money_reverse_exchange to_d, amount, currency
    end

    def reverse
      self.class.new(1.0 / value).freeze
    end

    FORMAT_ROUND = 3

    def format(cur1='', cur2='')
      cur1 = " #{cur1}" if cur1.present?
      cur2 = " #{cur2}" if cur2.present?
      "#{in_amount.round FORMAT_ROUND}#{cur1} → #{out_amount.round FORMAT_ROUND}#{cur2}"
    end

    def to_s
      format
    end

    def to_rate
      self
    end
  end
end
