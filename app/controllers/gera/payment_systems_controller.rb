# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class PaymentSystemsController < ApplicationController
    authorize_actions_for PaymentSystem

    EDIT_COLUMNS = %i[
      name icon_url currency
      income_enabled outcome_enabled
    ].freeze

    SHOW_COLUMNS = %i[
      id icon name currency
      income_enabled outcome_enabled
      actions
    ].freeze

    def index
      render locals: {
        payment_systems: PaymentSystem.order(:id),
        columns: SHOW_COLUMNS
      }
    end

    def show
      render locals: {
        payment_system: PaymentSystem.find(params[:id]),
        columns: SHOW_COLUMNS
      }
    end

    def new
      render locals: {
        payment_system: PaymentSystem.new,
        columns: EDIT_COLUMNS
      }
    end

    def create
      PaymentSystem.create! permitter_params
    rescue ActiveRecord::RecordInvalid => e
      render :new, locals: {
        payment_system: e.record,
        columns: EDIT_COLUMNS
      }
    end

    def edit
      render locals: {
        payment_system: PaymentSystem.find(params[:id]),
        columns: EDIT_COLUMNS
      }
    end

    def update
      respond_to do |format|
        if payment_system.update_attributes permitter_params
          format.html { redirect_to(payment_systems_path, notice: 'Status was successfully updated.') }
          format.json { respond_with_bip(payment_system) }
        else
          format.html { render action: 'edit', locals: { payment_system: payment_system, columns: EDIT_COLUMNS } }
          format.json { respond_with_bip(payment_system) }
        end
      end
    end

    private

    def payment_system
      @payment_system ||= PaymentSystem.find params[:id]
    end

    def permitter_params
      params[:payment_system].permit!
    end
  end
end
