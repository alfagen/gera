# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class DirectionRateHistoryIntervalsController < ApplicationController
    authorize_actions_for DirectionRate
    helper_method :payment_system_from, :payment_system_to
    helper_method :filter
    helper_method :history_intervals_enabled?

    def index
      respond_to do |format|
        format.html { render locals: { title: title, value_decimals: value_decimals } }
        format.json { render json: intervals }
      end
    end

    private

    def value_decimals
      if filter.value_type == 'comission'
        3
      else
        4
      end
    end

    def title
      "График конечного курса для направление #{filter.payment_system_from}->#{filter.payment_system_to}"
    end

    def filter
      @filter ||= DirectionRateHistoryIntervalFilter.new params.fetch(:direction_rate_history_interval_filter, {}).permit!
    end

    def prepare_rate_value(value)
      inverse? ? 1.0 / value : value
    end

    def inverse?
      @inverse ||= Money.from_amount(1, filter.payment_system_from.currency).exchange_to(filter.payment_system_to.currency).to_f < 1
    end

    def intervals
      scope = DirectionRateHistoryInterval
              .where(payment_system_to_id: filter.payment_system_to_id, payment_system_from_id: filter.payment_system_from_id)
              .order(:interval_from)

      case filter.value_type
      when 'rate'
        scope
          .pluck(:interval_from, :min_rate, :max_rate)
          .map { |time, min, max| [time.to_f * 1000, prepare_rate_value(min), prepare_rate_value(max), prepare_rate_value(min), prepare_rate_value(max)] }
      when 'comission'
        scope
          .pluck(:interval_from, :min_comission, :max_comission)
          .map { |time, min, max| [time.to_f * 1000, min, max, min, max] }
      else
        raise "Unknown value_type #{filter.value_type}"
      end
    end

    def history_intervals_enabled?
      Gera.enable_direction_rate_history_intervals
    end
  end
end
