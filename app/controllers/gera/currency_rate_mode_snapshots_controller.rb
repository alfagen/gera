# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class CurrencyRateModeSnapshotsController < ApplicationController
    authorize_actions_for CurrencyRateMode
    authority_actions activate: :create

    helper_method :view_mode

    def index
      redirect_to edit_currency_rate_mode_snapshot_path Universe.currency_rate_modes_repository.snapshot
    end

    def edit
      if snapshot.status_draft?
        render :edit, locals: {
          snapshot: snapshot
        }
      else
        redirect_to currency_rate_mode_snapshot_path snapshot
      end
    end

    def show
      if snapshot.status_draft?
        redirect_to edit_currency_rate_mode_snapshot_path snapshot
      else
        render :edit, locals: {
          snapshot: snapshot
        }
      end
    end

    def activate
      snapshot.transaction do
        CurrencyRateModeSnapshot.status_active.update_all status: :deactive
        snapshot.update status: :active
      end
      CurrencyRatesJob.perform_later if Rails.env.production?
      flash[:success] = 'Режимы активированы'
      redirect_to currency_rate_mode_snapshot_path snapshot
    end

    def update
      snapshot.update permitted_params
      respond_to do |format|
        format.json { respond_with_bip(snapshot) }
      end
    end

    def create
      flash[:success] = 'Создана новая матрица методов расчета'
      redirect_to edit_currency_rate_mode_snapshot_path(create_draft_snapshot)
    end

    private

    def view_mode
      if params[:view_mode] == 'calculations'
        :calculations
      else
        :methods
      end
    end

    def snapshot
      CurrencyRateModeSnapshot.find params[:id]
    end

    def find_last_draft_snapshot
      CurrencyRateModeSnapshot.status_draft.last
    end

    def create_draft_snapshot
      CurrencyRateModeSnapshot.create!
    end

    def permitted_params
      params.require(:currency_rate_mode_snapshot).permit!
    end
  end
end
