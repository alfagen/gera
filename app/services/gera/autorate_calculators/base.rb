# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'

module Gera
  module AutorateCalculators
    class Base
      include Virtus.model strict: true

      AUTO_COMISSION_GAP = 0.0001
      # Количество знаков после запятой для комиссии
      COMMISSION_PRECISION = 4

      attribute :exchange_rate
      attribute :external_rates

      delegate :position_from, :position_to, :autorate_from, :autorate_to,
               to: :exchange_rate

      def call
        raise NotImplementedError, "#{self.class}#call must be implemented"
      end

      protected

      # Округление комиссии до заданной точности
      # @param value [Numeric] значение комиссии
      # @raise [ArgumentError] если value nil
      def round_commission(value)
        raise ArgumentError, "Cannot round nil commission value" if value.nil?

        value.round(COMMISSION_PRECISION)
      end

      def could_be_calculated?
        !external_rates.nil? && exchange_rate.target_autorate_setting&.could_be_calculated?
      end

      def external_rates_in_target_position
        return nil unless external_rates.present?

        external_rates[(position_from - 1)..(position_to - 1)]
      end

      def external_rates_in_target_comission
        return [] unless external_rates_in_target_position.present?

        external_rates_in_target_position.compact.select do |rate|
          (autorate_from..autorate_to).include?(rate.target_rate_percent)
        end
      end
    end
  end
end
