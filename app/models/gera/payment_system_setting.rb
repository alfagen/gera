# frozen_string_literal: true

module Gera
  class PaymentSystemSetting < ApplicationRecord
    belongs_to :payment_system, class_name: 'Gera::PaymentSystem'
  end
end
