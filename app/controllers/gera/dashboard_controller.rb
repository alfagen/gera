# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class DashboardController < ApplicationController
    authority_actions tables_sizes: :read, status: :read

    def index
      redirect_to currency_rates_path
    end

    def tables_sizes
      render locals: {
        records: ApplicationRecord.tables_sizes
      }
    end
  end
end
