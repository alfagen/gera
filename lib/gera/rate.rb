require_relative 'rate_from_multiplicator'

module Gera
  class Rate < RateFromMultiplicator
    include Virtus.model strict: true

    attribute :in_amount, Float
    attribute :out_amount, Float

    def to_d
      out_amount.to_d / in_amount.to_d
    end

    def to_f
      to_d.to_f
    end

    def reverse
      self.class.new(in_amount: out_amount, out_amount: in_amount).freeze
    end
  end
end
