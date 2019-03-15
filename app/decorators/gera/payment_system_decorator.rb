# frozen_string_literal: true

module Gera
  class PaymentSystemDecorator < ApplicationDecorator
    delegate_all

    def icon
      h.ps_icon object, size: 32
    end

    def actions
      h.link_to t('.edit'), h.edit_payment_system_path(object), class: 'btn btn-outline btn-default btn-sm' if object.updatable_by? current_user
    end

    def self.decorated_class
      PaymentSystem
    end
  end
end
