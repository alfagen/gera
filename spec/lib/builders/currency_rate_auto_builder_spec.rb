# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateAutoBuilder do
    let!(:rate_source) { create(:rate_source_exmo, priority: 1) }
    let!(:external_rate_snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }

    before do
      rate_source.update!(actual_snapshot_id: external_rate_snapshot.id)
      allow(Gera).to receive(:default_cross_currency).and_return(:USD)
      allow(Gera).to receive(:cross_pairs).and_return({})
    end

    describe '#build_currency_rate' do
      context 'when currency pair is same (e.g., USD/USD)' do
        let(:currency_pair) { CurrencyPair.new('USD/USD') }
        subject { described_class.new(currency_pair: currency_pair) }

        it 'returns SuccessResult with rate_value 1' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::SuccessResult)
          expect(result.currency_rate.rate_value).to eq(1)
        end

        it 'sets mode to same' do
          result = subject.build_currency_rate
          expect(result.currency_rate.mode).to eq('same')
        end
      end

      context 'when direct rate exists in source' do
        let(:currency_pair) { CurrencyPair.new('BTC/USD') }
        subject { described_class.new(currency_pair: currency_pair) }

        let!(:external_rate) do
          create(:external_rate,
                 snapshot: external_rate_snapshot,
                 cur_from: Money::Currency.find(:BTC),
                 cur_to: Money::Currency.find(:USD),
                 rate_value: 50_000)
        end

        it 'returns SuccessResult from direct source' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::SuccessResult)
          expect(result.currency_rate.rate_value).to eq(50_000)
        end

        it 'sets mode to direct' do
          result = subject.build_currency_rate
          expect(result.currency_rate.mode).to eq('direct')
        end
      end

      context 'when cross rate needs to be calculated' do
        let(:currency_pair) { CurrencyPair.new('ETH/RUB') }
        subject { described_class.new(currency_pair: currency_pair) }

        let!(:eth_usd_rate) do
          create(:external_rate,
                 snapshot: external_rate_snapshot,
                 cur_from: Money::Currency.find(:ETH),
                 cur_to: Money::Currency.find(:USD),
                 rate_value: 3000)
        end

        let!(:usd_rub_rate) do
          create(:external_rate,
                 snapshot: external_rate_snapshot,
                 cur_from: Money::Currency.find(:USD),
                 cur_to: Money::Currency.find(:RUB),
                 rate_value: 95)
        end

        it 'returns SuccessResult with cross rate' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::SuccessResult)
        end

        it 'calculates cross rate correctly' do
          result = subject.build_currency_rate
          # ETH/RUB = ETH/USD * USD/RUB = 3000 * 95 = 285000
          expect(result.currency_rate.rate_value).to eq(285_000)
        end

        it 'sets mode to cross' do
          result = subject.build_currency_rate
          expect(result.currency_rate.mode).to eq('cross')
        end
      end

      context 'when no rate can be found' do
        # Using valid currencies that don't have external rates
        let(:currency_pair) { CurrencyPair.new('ZEC/NEO') }
        subject { described_class.new(currency_pair: currency_pair) }

        it 'returns ErrorResult' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::ErrorResult)
        end
      end
    end

    describe '#build_same' do
      let(:currency_pair) { CurrencyPair.new('EUR/EUR') }
      subject { described_class.new(currency_pair: currency_pair) }

      it 'returns CurrencyRate with rate_value 1 for same currencies' do
        result = subject.send(:build_same)
        expect(result.rate_value).to eq(1)
        expect(result.mode).to eq('same')
      end

      it 'returns nil for different currencies' do
        builder = described_class.new(currency_pair: CurrencyPair.new('BTC/USD'))
        expect(builder.send(:build_same)).to be_nil
      end
    end
  end
end
