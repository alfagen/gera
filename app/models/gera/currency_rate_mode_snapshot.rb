# frozen_string_literal: true

module Gera
  class CurrencyRateModeSnapshot < ApplicationRecord
    has_many :currency_rate_modes, dependent: :destroy

    scope :ordered, -> { order('status desc').order('created_at desc') }

    enum :status, %i[draft active deactive], prefix: true

    accepts_nested_attributes_for :currency_rate_modes

    before_validation do
      self.title = Time.zone.now.to_s if title.blank?
    end

    validates :title, presence: true, uniqueness: { case_sensitive: false }

    def create_modes!
      CurrencyPair.all.each do |pair|
        currency_rate_modes.create! currency_pair: pair
      end
      self
    end
  end
end
