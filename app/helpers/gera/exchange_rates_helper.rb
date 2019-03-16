# frozen_string_literal: true

module Gera
  module ExchangeRatesHelper
    def exchange_rate_cell_class(er)
      return unless er

      classes = []

      classes << 'rate-popover' if show_direction_popover?

      classes << if er.comission_percents <= 0
                   'text-danger'
                 else
                   'text-success'
      end

      classes.join ' '
    end
  end
end
