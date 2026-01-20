# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'

module Gera
  module AutorateCalculators
    class Base
      include Virtus.model strict: true

      AUTO_COMISSION_GAP = 0.001

      attribute :exchange_rate
      attribute :external_rates

      delegate :position_from, :position_to, :autorate_from, :autorate_to,
               to: :exchange_rate

      def call
        raise NotImplementedError, "#{self.class}#call must be implemented"
      end

      protected

      def could_be_calculated?
        !external_rates.nil? && exchange_rate.target_autorate_setting&.could_be_calculated?
      end

      def external_rates_in_target_position
        return nil unless external_rates.present?

        external_rates[(position_from - 1)..(position_to - 1)]
      end

      def external_rates_in_target_comission
        return [] unless external_rates_in_target_position.present?

        external_rates_in_target_position.select do |rate|
          (autorate_from..autorate_to).include?(target_rate_percent(rate))
        end
      end

      # Вычисляет процент комиссии из курса Manul
      # @param rate [Hash] хеш от Manul API с ключом 'rate'
      # @return [Float] процент комиссии относительно базового курса
      def target_rate_percent(rate)
        calculate_rate_commission(rate['rate'], base_rate)
      end

      # Возвращает ID обменника из хеша Manul
      # @param rate [Hash] хеш от Manul API с ключом 'changer_id'
      # @return [Integer, nil] ID обменника
      def changer_id(rate)
        rate['changer_id']
      end

      private

      def base_rate
        @base_rate ||= exchange_rate.currency_rate.rate_value
      end

      def calculate_rate_commission(finite_rate, base_rate_value)
        finite = finite_rate.to_f
        base = base_rate_value.to_f

        normalized_finite = finite < 1 && base > 1 ? 1.0 / finite : finite

        ((base - normalized_finite) / base) * 100
      end
    end
  end
end
