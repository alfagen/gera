# frozen_string_literal: true

module Gera
  class TargetAutorateSetting < ApplicationRecord
    validates :position_from, :position_to, :autorate_from, :autorate_to, presence: true
    validates :position_from, numericality: { less_than: :position_to }
    validates :position_to, numericality: { greater_than: :position_from }
  end
end
