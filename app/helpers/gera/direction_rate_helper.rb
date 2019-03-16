# frozen_string_literal: true

module Gera
  module DirectionRateHelper
    def exchange_rate_cell_data_attr(direction)
      rate_cell_data_attr(direction).merge href: operator_exchange_rate_path(direction.exchange_rate)
    end

    def direction_rate_cell_data_attr(direction)
      rate_cell_data_attr(direction).merge href: direction_rate_path(direction.direction_rate.try(:id) || 0)
    end

    def rate_cell_data_attr(direction)
      return {} unless show_direction_popover?

      {
        toggle: 'ajax-popover',
        container: :body,
        popover_content_url: details_exchange_rate_path(direction.exchange_rate),
        trigger: :hover,
        html: 'true',
        placement: :bottom,
        animation: false,
        delay: 0
      }
    end

    def rate_humanized_description(rate_value, cur_from, cur_to)
      if rate_value < 1
        t '.sell_for', cur_to: cur_to, value: (1.0 / rate_value).round(3), cur_from: cur_from
      else
        t '.buy_for', cur_to: cur_to, value: rate_value.round(3), cur_from: cur_from
      end
    end
  end
end
