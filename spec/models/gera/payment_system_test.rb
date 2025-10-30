# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gera::PaymentSystem', type: :model do
  fixtures :gera_payment_systems

  describe "PaymentSystem model" do
    it "loads fixtures correctly" do
      expect(gera_payment_systems(:one)).to be_persisted
      expect(gera_payment_systems(:one).name).to eq "Yandex Money"
      expect(gera_payment_systems(:one).currency).to eq "RUB"
    end

    it "validates presence of name" do
      ps = Gera::PaymentSystem.new
      expect(ps).not_to be_valid
      expect(ps.errors[:name]).to include "can't be blank"
    end

    it "creates new payment system" do
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