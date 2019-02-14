# frozen_string_literal: true

require_relative 'application_authorizer'
module Gera
  class DirectionRateAuthorizer < ApplicationAuthorizer
    self.adjectives = %i[readable]
  end
end
