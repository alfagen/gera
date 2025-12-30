# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSource do
    describe 'associations' do
      let(:source) { create(:rate_source_exmo) }

      it 'has many snapshots' do
        expect(source).to respond_to(:snapshots)
      end

      it 'has many external_rates' do
        expect(source).to respond_to(:external_rates)
      end

      it 'belongs to actual_snapshot' do
        expect(source).to respond_to(:actual_snapshot)
      end
    end

    describe 'scopes' do
      let!(:enabled_source) { create(:rate_source_exmo, is_enabled: true, priority: 1) }
      let!(:disabled_source) { create(:rate_source_cbr, is_enabled: false, priority: 2) }

      describe '.ordered' do
        it 'orders by priority' do
          expect(RateSource.ordered.first).to eq(enabled_source)
        end
      end

      describe '.enabled' do
        it 'returns only enabled sources' do
          expect(RateSource.enabled).to include(enabled_source)
          expect(RateSource.enabled).not_to include(disabled_source)
        end
      end
    end

    describe 'callbacks' do
      describe 'before_create' do
        it 'sets priority if not provided' do
          source = RateSource.create!(type: 'Gera::RateSourceManual', key: 'test_manual')
          expect(source.priority).to be_present
        end
      end

      describe 'before_validation' do
        it 'sets title from class name if blank' do
          source = RateSource.new(type: 'Gera::RateSourceManual')
          source.valid?
          expect(source.title).to be_present
        end

        it 'sets key from class name if blank' do
          source = RateSource.new(type: 'Gera::RateSourceManual')
          source.valid?
          expect(source.key).to be_present
        end
      end
    end

    describe '.get!' do
      let!(:source) { create(:rate_source_exmo) }

      it 'returns source by type' do
        expect(RateSourceExmo.get!).to eq(source)
      end
    end

    describe '#find_rate_by_currency_pair' do
      let(:source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: source) }
      let(:currency_pair) { CurrencyPair.new('BTC/USD') }
      let!(:external_rate) do
        create(:external_rate,
               snapshot: snapshot,
               cur_from: Money::Currency.find(:BTC),
               cur_to: Money::Currency.find(:USD),
               rate_value: 50_000)
      end

      before { source.update!(actual_snapshot_id: snapshot.id) }

      it 'finds rate by currency pair' do
        expect(source.find_rate_by_currency_pair(currency_pair)).to eq(external_rate)
      end

      it 'returns nil when rate not found' do
        unknown_pair = CurrencyPair.new('ETH/EUR')
        expect(source.find_rate_by_currency_pair(unknown_pair)).to be_nil
      end
    end

    describe '#find_rate_by_currency_pair!' do
      let(:source) { create(:rate_source_exmo) }

      it 'raises RateNotFound when rate not found' do
        currency_pair = CurrencyPair.new('BTC/USD')
        expect { source.find_rate_by_currency_pair!(currency_pair) }.to raise_error(RateSource::RateNotFound)
      end
    end

    describe '#is_currency_supported?' do
      let(:source) { create(:rate_source_exmo) }

      it 'returns true for supported currency' do
        expect(source.is_currency_supported?(:BTC)).to be true
      end

      it 'returns false for unsupported currency' do
        expect(source.is_currency_supported?(:KZT)).to be false
      end

      it 'accepts Money::Currency objects' do
        currency = Money::Currency.find(:BTC)
        expect(source.is_currency_supported?(currency)).to be true
      end
    end

    describe '#actual_rates' do
      let(:source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: source) }
      let!(:external_rate) { create(:external_rate, snapshot: snapshot) }

      before { source.update!(actual_snapshot_id: snapshot.id) }

      it 'returns external rates from actual snapshot' do
        expect(source.actual_rates).to include(external_rate)
      end
    end

    describe '#to_s' do
      let(:source) { create(:rate_source_exmo, title: 'EXMO Exchange') }

      it 'returns title' do
        expect(source.to_s).to eq('EXMO Exchange')
      end
    end
  end
end
