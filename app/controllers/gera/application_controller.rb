# frozen_string_literal: true

module Gera
  class ApplicationController < ::ApplicationController
    helper Gera::ApplicationHelper
    helper Gera::CurrencyRateModesHelper
    helper Gera::DirectionRateHelper

    protect_from_forgery with: :exception

    ensure_authorization_performed

    helper_method :payment_systems
    helper_method :query_params

    private

    def query_params
      params.fetch(:q, {}).permit!
    end

    def app_title
      "GERA #{VERSION}"
    end

    def payment_systems
      @payment_systems ||= Universe.payment_systems.available
    end
  end
end
