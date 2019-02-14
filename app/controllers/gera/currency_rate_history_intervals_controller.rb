# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class CurrencyRateHistoryIntervalsController < ApplicationController
    authorize_actions_for CurrencyRate
    helper_method :filter

    def index
      respond_to do |format|
        format.html { render locals: { title: title, value_decimals: value_decimals } }
        format.json { render json: intervals }
      end
    end

    private

    def value_decimals
      4
    end

    def title
      "График базового курса для направление #{filter.cur_from}->#{filter.cur_to}"
    end

    def filter
      @filter ||= CurrencyRateHistoryIntervalFilter.new params.fetch(:currency_rate_history_interval_filter, {}).permit!
    end

    def prepare_rate_value(value)
      inverse? ? 1.0 / value : value
    end

    def inverse?
      false
    end

    def intervals
      scope = Gera::CurrencyRateHistoryInterval
              .where(cur_to_id: filter.currency_to.local_id, cur_from_id: filter.currency_from.local_id)
              .order(:interval_from)

      case filter.value_type
      when 'rate'
        scope
          .pluck(:interval_from, :min_rate, :max_rate)
          .map { |time, min, max| [time.to_f * 1000, prepare_rate_value(min), prepare_rate_value(max), prepare_rate_value(min), prepare_rate_value(max)] }
      else
        raise "Unknown value_type #{filter.value_type}"
      end
    end
  end
end
