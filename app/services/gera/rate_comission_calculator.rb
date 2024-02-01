# frozen_string_literal: true

module Gera
  class RateComissionCalculator
    include Virtus.model strict: true

    AUTO_COMISSION_GAP = 0.05
    NOT_ALLOWED_COMISSION_RANGE = (0.7..1.4)

    attribute :exchange_rate
    attribute :external_rates

    delegate  :in_currency, :payment_system_from, :payment_system_to, 
              :out_currency, :fixed_comission, :position_from, 
              :position_to, :autorate_from, :autorate_to, to: :exchange_rate

    def auto_comission
      calculate_allowed_comission(commission)
    end

    def auto_comission_by_reserve
      average(auto_rate_by_reserve_from, auto_rate_by_reserve_to)
    end

    def comission_by_base_rate
      average(auto_rate_by_base_from, auto_rate_by_base_to)
    end

    def auto_rate_by_base_from
      return 0.0 unless auto_rates_by_base_rate_ready?

      calculate_auto_rate_by_base_rate_min_boundary
    end

    def auto_rate_by_base_to
      return 0.0 unless auto_rates_by_base_rate_ready?

      calculate_auto_rate_by_base_rate_max_boundary
    end

    def auto_rate_by_reserve_from
      return 0.0 unless auto_rates_by_reserve_ready?

      calculate_auto_rate_by_reserve_min_boundary
    end

    def auto_rate_by_reserve_to
      return 0.0 unless auto_rates_by_reserve_ready?

      calculate_auto_rate_by_reserve_max_boundary
    end

    def current_base_rate
      @current_base_rate ||= Gera::CurrencyRateHistoryInterval.where(cur_from_id: in_currency.local_id, cur_to_id: out_currency.local_id).last.avg_rate
    end

    def average_base_rate
      @average_base_rate ||= Gera::CurrencyRateHistoryInterval.where('interval_from > ?', DateTime.now.utc - 24.hours).where(cur_from_id: in_currency.local_id, cur_to_id: out_currency.local_id).average(:avg_rate)
    end

    def auto_comission_from
      @auto_comission_from ||= auto_rate_by_reserve_from + auto_rate_by_base_from
    end

    def auto_comission_to
      @auto_comission_to_boundary ||= auto_rate_by_reserve_to + auto_rate_by_base_to
    end

    def bestchange_delta
      auto_comission_by_external_comissions
    end

    private

    def auto_rates_by_reserve_ready?
      income_auto_rate_setting&.reserves_positive? && outcome_auto_rate_setting&.reserves_positive? && income_reserve_checkpoint.present? && outcome_reserve_checkpoint.present?
    end

    def auto_rates_by_base_rate_ready?
      income_base_rate_checkpoint.present? && outcome_base_rate_checkpoint.present?
    end

    def income_auto_rate_setting
      @income_auto_rate_setting ||= payment_system_from.auto_rate_settings.find_by(direction: 'income')
    end

    def outcome_auto_rate_setting
      @outcome_auto_rate_setting ||= payment_system_to.auto_rate_settings.find_by(direction: 'outcome')
    end

    def income_reserve_checkpoint
      @income_reserve_checkpoint ||= income_auto_rate_setting && 
        income_auto_rate_setting.checkpoint(
          base_value: income_auto_rate_setting&.reserve,
          additional_value: income_auto_rate_setting&.base,
          type: 'reserve'
        )
    end

    def outcome_reserve_checkpoint
      @outcome_reserve_checkpoint ||= outcome_auto_rate_setting && outcome_auto_rate_setting.checkpoint(
        base_value: outcome_auto_rate_setting&.reserve,
        additional_value: outcome_auto_rate_setting&.base,
        type: 'reserve'
      )
    end

    def income_base_rate_checkpoint
      @income_base_rate_checkpoint ||= income_auto_rate_setting && income_auto_rate_setting.checkpoint(
        base_value: current_base_rate,
        additional_value: average_base_rate,
        type: 'by_base_rate'
      )
    end

    def outcome_base_rate_checkpoint
      @outcome_base_rate_checkpoint ||= outcome_auto_rate_setting && outcome_auto_rate_setting.checkpoint(
        base_value: current_base_rate,
        additional_value: average_base_rate,
        type: 'by_base_rate'
      )
    end

    def calculate_auto_rate_by_reserve_min_boundary
      average(income_reserve_checkpoint.min_boundary, outcome_reserve_checkpoint.min_boundary)
    end

    def calculate_auto_rate_by_reserve_max_boundary
      average(income_reserve_checkpoint.max_boundary, outcome_reserve_checkpoint.max_boundary)
    end

    def calculate_auto_rate_by_base_rate_min_boundary
      average(income_base_rate_checkpoint.min_boundary, outcome_base_rate_checkpoint.min_boundary)
    end

    def calculate_auto_rate_by_base_rate_max_boundary
      average(income_base_rate_checkpoint.max_boundary, outcome_base_rate_checkpoint.max_boundary)
    end

    def average(a, b)
      ((a + b) / 2.0).round(2)
    end

    def commission
      @commission ||= auto_comission_by_external_comissions + auto_comission_by_reserve + comission_by_base_rate
    end

    def could_be_calculated?
      external_rates.present? && exchange_rate.target_autorate_setting&.could_be_calculated?
    end

    def auto_commision_range
      @auto_commision_range ||= (auto_comission_from..auto_comission_to)
    end

    def auto_comission_by_external_comissions
      @auto_comission_by_external_comissions ||= begin
        return 0 unless could_be_calculated?

        external_rates_in_target_position = external_rates[(position_from - 1)..(position_to - 1)]
        external_rates_in_target_comission = external_rates_in_target_position.select { |rate| ((autorate_from + AUTO_COMISSION_GAP)..(autorate_to)).include?(rate.target_rate_percent) }
        return autorate_from if external_rates_in_target_comission.empty?

        target_comission = external_rates_in_target_comission.first.target_rate_percent - AUTO_COMISSION_GAP
        rates_before_target_position = external_rates.select { |rate| rate.target_rate_percent < target_comission }

        (rates_before_target_position.count + 1) < position_from ? autorate_from : target_comission
      end
    end

    def calculate_allowed_comission(comission)
      NOT_ALLOWED_COMISSION_RANGE.include?(comission) ? NOT_ALLOWED_COMISSION_RANGE.min : comission
    end
  end
end
