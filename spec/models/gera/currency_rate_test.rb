# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gera::CurrencyRate', type: :model do
  fixtures :gera_currency_rates, :gera_rate_sources, :gera_external_rate_snapshots

  describe "CurrencyRate model" do
    it "loads fixtures correctly" do
      rate = gera_currency_rates(:usd_rub)
      expect(rate).to be_persisted
      expect(rate.rate).to eq 60.5
      expect(rate.currency_from).to eq "USD"
      expect(rate.currency_to).to eq "RUB"
      expect(rate.mode).to eq "direct"
    end

    it "creates new currency rate" do
      rate = Gera::CurrencyRate.create!(
        currency_from: "EUR",
        currency_to: "USD",
        rate: 1.2,
        rate_source: gera_rate_sources(:one),
        external_rate_snapshot: gera_external_rate_snapshots(:one),
        mode: "direct"
      )
      expect(rate).to be_persisted
      expect(rate.rate).to eq 1.2
    end

    it "handles different modes" do
      direct_rate = gera_currency_rates(:usd_rub)
      inverse_rate = gera_currency_rates(:rub_usd)

      expect(direct_rate.mode).to eq "direct"
      expect(inverse_rate.mode).to eq "inverse"
    end
  end
end