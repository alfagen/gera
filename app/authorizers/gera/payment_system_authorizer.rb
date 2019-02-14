# frozen_string_literal: true

require_relative 'application_authorizer'
module Gera
  class PaymentSystemAuthorizer < ApplicationAuthorizer
    # Для изменения не админами запрещено менять все кроме разрешенных
    WHITE_LIST = %w[income_enabled outcome_enabled referal_output_enabled].freeze

    def self.restricted_attributes
      (Gera::PaymentSystem.attribute_names - WHITE_LIST).freeze
    end
  end
end
