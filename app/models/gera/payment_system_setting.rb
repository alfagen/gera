# frozen_string_literal: true

module Gera
  class PaymentSystemSetting < ApplicationRecord
    include Authority::Abilities

    belongs_to :payment_system, class_name: 'Gera::PaymentSystem'
  end
end
