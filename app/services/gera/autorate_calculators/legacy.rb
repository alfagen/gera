# frozen_string_literal: true

module Gera
  module AutorateCalculators
    # Legacy калькулятор - сохраняет текущее поведение.
    # Вычитает фиксированный GAP из комиссии первого конкурента в диапазоне.
    # Может "перепрыгивать" позиции выше целевого диапазона.
    class Legacy < Base
      def call
        return 0 unless could_be_calculated?
        return autorate_from unless external_rates_in_target_position.present?
        return autorate_from if external_rates_in_target_comission.empty?

        external_rates_in_target_comission.first.target_rate_percent - AUTO_COMISSION_GAP
      end
    end
  end
end
