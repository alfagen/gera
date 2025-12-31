# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateModesRepository do
    subject(:repository) { described_class.new }

    describe '#snapshot' do
      it 'creates a new active snapshot if none exists' do
        expect { repository.snapshot }.to change(CurrencyRateModeSnapshot, :count).by(1)
        expect(repository.snapshot.status).to eq('active')
      end

      it 'returns existing active snapshot' do
        existing = CurrencyRateModeSnapshot.create!(status: :active)
        expect(repository.snapshot).to eq(existing)
      end
    end

    describe '#find_currency_rate_mode_by_pair' do
      let!(:snapshot) { CurrencyRateModeSnapshot.create!(status: :active) }
      let!(:currency_rate_mode) do
        create(:currency_rate_mode,
               snapshot: snapshot,
               cur_from: 'USD',
               cur_to: 'RUB')
      end

      it 'returns currency rate mode for pair' do
        pair = CurrencyPair.new(Money::Currency.find('USD'), Money::Currency.find('RUB'))
        result = repository.find_currency_rate_mode_by_pair(pair)
        expect(result).to eq(currency_rate_mode)
      end

      it 'returns nil for non-existent pair' do
        unknown_pair = CurrencyPair.new(Money::Currency.find('EUR'), Money::Currency.find('BTC'))
        expect(repository.find_currency_rate_mode_by_pair(unknown_pair)).to be_nil
      end
    end
  end
end
