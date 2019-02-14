# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class ExternalRatesController < ApplicationController
    def index
      if params[:rate_source_id].present?
        redirect_to external_rate_snapshots_path(rate_source_id: params[:rate_source_id])
      else
        redirect_to rate_sources_path
      end
    end

    def show
      render locals: {
        external_rate: external_rate
      }
    end

    private

    def external_rate
      ExternalRate.find params[:id]
    end
  end
end
