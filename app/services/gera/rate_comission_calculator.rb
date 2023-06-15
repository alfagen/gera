# frozen_string_literal: true

module Gera
  class RateComissionCalculator
    include Virtus.model strict: true

    AUTO_COMISSION_GAP = 0.01
    NOT_ALLOWED_COMISSION_RANGE = (0.7..1.4)

    attribute :exchange_rate
    attribute :external_rates

    delegate  :auto_comission_by_base_rate?, :in_currency, :payment_system_from,
              :payment_system_to, :out_currency, :fixed_comission, to: :exchange_rate

    def auto_comission
      target_value = external_rates_ready? ? auto_comission_by_external_comissions : commission
      calculate_allowed_comission(target_value)
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
      auto_comission_by_external_comissions - commission
    end

    private

    def auto_rates_by_reserve_ready?
      income_reserve_checkpoint.present? && outcome_reserve_checkpoint.present? && income_reserve_checkpoint.reserves_positive? && outcome_reserve_checkpoint.reserves_positive?
    end

    def auto_rates_by_base_rate_ready?
      income_base_rate_checkpoint.present? && outcome_base_rate_checkpoint.present? && income_base_rate_checkpoint.base.positive? && outcome_base_rate_checkpoint.base.positive?
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
      @commission ||= begin
        comission_percents = auto_comission_by_reserve
        comission_percents += comission_by_base_rate if auto_comission_by_base_rate?
        comission_percents
      end
    end

    def external_rates_ready?
      external_rates.present?
    end

    def auto_commision_range
      @auto_commision_range ||= (auto_comission_from..auto_comission_to)
    end

    def auto_comission_by_external_comissions
      @auto_comission_by_external_comissions ||= begin
        external_rates_with_similar_comissions = external_rates.select { |rate| auto_commision_range.include?(rate.target_rate_percent) }
        return commission if external_rates_with_similar_comissions.empty?

        external_rates_with_similar_comissions.sort! { |a, b| a.target_rate_percent <=> b.target_rate_percent }
        external_rates_with_similar_comissions.last.target_rate_percent - AUTO_COMISSION_GAP
      end
    end

    def calculate_allowed_comission(comission)
      return comission unless NOT_ALLOWED_COMISSION_RANGE.include?(comission)

      comission_outside_disallowed_range(comission)
    end

    def comission_outside_disallowed_range(comission)
      max, min = NOT_ALLOWED_COMISSION_RANGE.max, NOT_ALLOWED_COMISSION_RANGE.min
      distance_to_max = (max - comission).abs
      distance_to_min = (min - comission).abs
      distance_to_min < distance_to_max ? distance_to_min - AUTO_COMISSION_GAP : distance_to_max + AUTO_COMISSION_GAP
    end
  end
end
