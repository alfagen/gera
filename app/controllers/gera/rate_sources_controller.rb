# frozen_string_literal: true

require_relative 'application_controller'
module Gera
  class RateSourcesController < ApplicationController
    authorize_actions_for RateSource
  end
end
