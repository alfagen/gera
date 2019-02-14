# frozen_string_literal: true

require_relative 'application_authorizer'
module Gera
  class ExchangeRateAuthorizer < ApplicationAuthorizer
    self.adjectives = %i[readable updatable]
  end
end
