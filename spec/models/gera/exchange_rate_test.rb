# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gera::ExchangeRate', type: :model do
  fixtures :gera_payment_systems, :gera_exchange_rates

  describe "ExchangeRate model" do
    it "loads fixtures correctly" do
      rate = gera_exchange_rates(:one)
      expect(rate).to be_persisted
      expect(rate.value).to eq 1.5
      expect(rate.payment_system_from).to eq gera_payment_systems(:one)
      expect(rate.payment_system_to).to eq gera_payment_systems(:two)
    end

    it "creates new exchange rate" do
      rate = Gera::ExchangeRate.create!(
        payment_system_from: gera_payment_systems(:btc),
        payment_system_to: gera_payment_systems(:usd),
        value: 2.5,
        is_enabled: true
      )
      expect(rate).to be_persisted
      expect(rate.value).to eq 2.5
    end

    it "has currency assignments" do
      rate = gera_exchange_rates(:btc_to_usd)
      expect(rate.in_cur).to eq "BTC"
      expect(rate.out_cur).to eq "USD"
    end
  end
end