# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRatesRepository do
    subject(:repository) { described_class.new }

    let!(:currency_rate_snapshot) { create(:currency_rate_snapshot) }
    let!(:currency_rate) do
      create(:currency_rate,
             snapshot: currency_rate_snapshot,
             cur_from: Money::Currency.find('USD'),
             cur_to: Money::Currency.find('RUB'))
    end

    describe '#snapshot' do
      it 'returns the last currency rate snapshot' do
        expect(repository.snapshot).to eq(currency_rate_snapshot)
      end

      it 'raises error when no snapshot exists' do
        CurrencyRateSnapshot.delete_all
        new_repository = described_class.new
        expect { new_repository.snapshot }.to raise_error(RuntimeError, 'No actual snapshot')
      end
    end

    describe '#find_currency_rate_by_pair' do
      it 'returns currency rate for existing pair' do
        pair = currency_rate.currency_pair
        expect(repository.find_currency_rate_by_pair(pair)).to eq(currency_rate)
      end

      it 'raises UnknownPair for non-existent pair' do
        unknown_pair = CurrencyPair.new(Money::Currency.find('EUR'), Money::Currency.find('BTC'))
        expect { repository.find_currency_rate_by_pair(unknown_pair) }
          .to raise_error(CurrencyRatesRepository::UnknownPair)
      end
    end

    describe '#get_currency_rate_by_pair' do
      it 'returns currency rate for existing pair' do
        pair = currency_rate.currency_pair
        expect(repository.get_currency_rate_by_pair(pair)).to eq(currency_rate)
      end

      it 'returns a new frozen CurrencyRate for unknown pair' do
        unknown_pair = CurrencyPair.new(Money::Currency.find('EUR'), Money::Currency.find('BTC'))
        result = repository.get_currency_rate_by_pair(unknown_pair)
        expect(result).to be_a(CurrencyRate)
        expect(result).to be_frozen
        expect(result.currency_pair).to eq(unknown_pair)
      end
    end
  end
end
