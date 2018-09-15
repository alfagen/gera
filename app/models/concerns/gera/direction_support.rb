module GERA
  module DirectionSupport
    def direction=(value)
      self.payment_system_from = value.payment_system_from
      self.payment_system_to = value.payment_system_to
    end

    def direction
      ::GERA::Direction.new(ps_from: payment_system_from, ps_to: payment_system_to).freeze
    end
  end
end
