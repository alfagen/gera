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
          (autorate_from..autorate_to).include?(rate.target_rate_percent)
        end
      end
    end
  end
end
