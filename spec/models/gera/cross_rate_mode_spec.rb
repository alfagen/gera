# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CrossRateMode do
    describe 'associations' do
      let(:mode_snapshot) { create(:currency_rate_mode_snapshot) }
      let(:currency_rate_mode) { create(:currency_rate_mode, snapshot: mode_snapshot) }
      let(:cross_mode) { create(:cross_rate_mode, currency_rate_mode: currency_rate_mode) }

      it 'belongs to currency_rate_mode' do
        expect(cross_mode).to respond_to(:currency_rate_mode)
        expect(cross_mode.currency_rate_mode).to eq(currency_rate_mode)
      end

      it 'belongs to rate_source optionally' do
        expect(cross_mode).to respond_to(:rate_source)
      end
    end

    describe 'CurrencyPairSupport' do
      it 'includes CurrencyPairSupport module' do
        expect(CrossRateMode.include?(CurrencyPairSupport)).to be true
      end
    end

    describe '#title' do
      let(:mode_snapshot) { create(:currency_rate_mode_snapshot) }
      let(:currency_rate_mode) { create(:currency_rate_mode, snapshot: mode_snapshot) }

      context 'with rate source' do
        let(:rate_source) { create(:rate_source_exmo) }
        let(:cross_mode) do
          create(:cross_rate_mode,
                 currency_rate_mode: currency_rate_mode,
                 rate_source: rate_source,
                 cur_from: 'BTC',
                 cur_to: 'USD')
        end

        it 'includes currency pair and rate source' do
          expect(cross_mode.title).to include('BTC/USD')
          expect(cross_mode.title).not_to include('auto')
        end
      end

      context 'without rate source' do
        let(:cross_mode) do
          create(:cross_rate_mode,
                 currency_rate_mode: currency_rate_mode,
                 rate_source: nil,
                 cur_from: 'BTC',
                 cur_to: 'USD')
        end

        it 'shows auto as source' do
          expect(cross_mode.title).to include('BTC/USD')
          expect(cross_mode.title).to include('auto')
        end
      end
    end
  end
end
