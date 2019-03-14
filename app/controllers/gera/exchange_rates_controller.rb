# frozen_string_literal: true

require_relative 'application_controller'

module Gera
  class ExchangeRatesController < ApplicationController
    authorize_actions_for ExchangeRate

    def show
      render locals: {
        exchange_rate: exchange_rate
      }
    end

    def details
      render 'direction_details', locals: { direction: exchange_rate.direction }, layout: nil
    end

    private

    def exchange_rate
      @exchange_rate ||= ExchangeRate.find params[:id]
    end
  end
end
