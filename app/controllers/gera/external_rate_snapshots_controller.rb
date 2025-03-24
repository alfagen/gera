# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class ExternalRateSnapshotsController < ApplicationController
    authorize_actions_for ExchangeRate

    PER_PAGE = 25
    helper_method :rate_source

    def index
      render locals: {
        snapshots: snapshots
      }
    end

    def show
      snapshot = ExternalRateSnapshot.find params[:id]

      render locals: {
        snapshot: snapshot
      }
    end

    private

    def rate_source
      RateSource.find params[:rate_source_id]
    end

    def snapshots
      rate_source.snapshots.ordered.page(params[:page]).per(params[:per] || PER_PAGE)
    end
  end
end
