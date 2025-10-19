# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gera::PaymentSystem', type: :model do
  describe "PaymentSystem model" do
    it "creates new payment system with factory bot" do
      ps = create :gera_payment_system
      expect(ps).to be_persisted
      expect(ps.name).to be_present
      expect(ps.currency).to be_present
    end

    it "validates presence of name" do
      ps = Gera::PaymentSystem.new
      expect(ps).not_to be_valid
      expect(ps.errors[:name]).to include "can't be blank"
    end

    it "creates new payment system manually" do
      ps = Gera::PaymentSystem.create!(
        name: "Test System",
        currency: "USD",
        income_enabled: true,
        outcome_enabled: true,
        is_available: true
      )
      expect(ps).to be_persisted
      expect(ps.name).to eq "Test System"
    end
  end
end