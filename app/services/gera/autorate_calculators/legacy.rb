# frozen_string_literal: true

module Gera
  module AutorateCalculators
    # Legacy калькулятор - сохраняет текущее поведение.
    # Вычитает фиксированный GAP из комиссии первого конкурента в диапазоне.
    # Может "перепрыгивать" позиции выше целевого диапазона.
    class Legacy < Base
      def call
        unless could_be_calculated?
          log_fallback("could_be_calculated? = false", 0)
          return 0
        end

        unless external_rates_in_target_position.present?
          log_fallback("no rates in target position [#{position_from}..#{position_to}]", autorate_from)
          return autorate_from
        end

        if external_rates_in_target_comission.empty?
          log_fallback("no rates in commission range [#{autorate_from}..#{autorate_to}]", autorate_from)
          return autorate_from
        end

        external_rates_in_target_comission.first.target_rate_percent - AUTO_COMISSION_GAP
      end

      private

      def log_fallback(reason, value)
        return unless defined?(Rails) && Rails.logger

        Rails.logger.info { "[Legacy] exchange_rate_id=#{exchange_rate.id}: #{reason}, returning #{value}" }
      end
    end
  end
end
