# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateDirectBuilder do
    let!(:rate_source) { create(:rate_source_exmo) }
    let!(:external_rate_snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }
    let(:currency_pair) { CurrencyPair.new('BTC/USD') }

    before do
      rate_source.update!(actual_snapshot_id: external_rate_snapshot.id)
    end

    describe '#build_currency_rate' do
      subject { described_class.new(currency_pair: currency_pair, source: rate_source) }

      context 'when external rate exists' do
        let!(:external_rate) do
          create(:external_rate,
                 snapshot: external_rate_snapshot,
                 cur_from: Money::Currency.find(:BTC),
                 cur_to: Money::Currency.find(:USD),
                 rate_value: 50_000)
        end

        it 'returns SuccessResult' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::SuccessResult)
          expect(result.success?).to be true
        end

        it 'builds CurrencyRate with correct attributes' do
          result = subject.build_currency_rate
          currency_rate = result.currency_rate

          expect(currency_rate.currency_pair).to eq(currency_pair)
          expect(currency_rate.rate_value).to eq(50_000)
          expect(currency_rate.rate_source).to eq(rate_source)
          expect(currency_rate.mode).to eq('direct')
          expect(currency_rate.external_rate_id).to eq(external_rate.id)
        end
      end

      context 'when currency is not supported by source' do
        # Using valid currencies not supported by EXMO (KZT is not in EXMO's supported list)
        let(:currency_pair) { CurrencyPair.new('KZT/USD') }

        it 'returns ErrorResult' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::ErrorResult)
          expect(result.error?).to be true
        end
      end

      context 'when external rate does not exist' do
        let(:currency_pair) { CurrencyPair.new('BCH/EUR') }

        it 'returns ErrorResult' do
          result = subject.build_currency_rate
          expect(result).to be_a(CurrencyRateBuilder::ErrorResult)
          expect(result.error?).to be true
        end
      end
    end
  end
end
