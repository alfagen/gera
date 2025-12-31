# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExternalRate do
    describe 'associations' do
      let(:rate_source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }
      let(:rate) { create(:external_rate, snapshot: snapshot) }

      it 'belongs to source' do
        expect(rate).to respond_to(:source)
        expect(rate.source).to eq(rate_source)
      end

      it 'belongs to snapshot' do
        expect(rate).to respond_to(:snapshot)
        expect(rate.snapshot).to eq(snapshot)
      end
    end

    describe 'scopes' do
      describe '.ordered' do
        let(:rate_source) { create(:rate_source_exmo) }
        let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }
        let!(:rate1) { create(:external_rate, snapshot: snapshot, cur_from: Money::Currency.find(:BTC), cur_to: Money::Currency.find(:USD)) }
        let!(:rate2) { create(:external_rate, snapshot: snapshot, cur_from: Money::Currency.find(:ETH), cur_to: Money::Currency.find(:USD)) }

        it 'orders by cur_from and cur_to' do
          expect(ExternalRate.ordered).to eq([rate1, rate2])
        end
      end
    end

    describe 'callbacks' do
      let(:rate_source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }

      describe 'before_validation' do
        it 'sets source from snapshot if blank' do
          rate = ExternalRate.new(snapshot: snapshot, cur_from: 'btc', cur_to: 'usd', rate_value: 50_000)
          rate.valid?
          expect(rate.source).to eq(rate_source)
        end

        it 'upcases currencies' do
          rate = ExternalRate.new(snapshot: snapshot, cur_from: 'btc', cur_to: 'usd', rate_value: 50_000)
          rate.valid?
          expect(rate.cur_from).to eq('BTC')
          expect(rate.cur_to).to eq('USD')
        end
      end
    end

    describe '#dump' do
      let(:rate_source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }
      let(:rate) { create(:external_rate, snapshot: snapshot) }

      it 'returns hash with specific attributes' do
        dump = rate.dump
        expect(dump.keys.map(&:to_s)).to match_array(%w[id cur_from cur_to rate_value source_id created_at])
      end
    end

    describe 'CurrencyPairSupport' do
      let(:rate_source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }
      let(:rate) do
        create(:external_rate,
               snapshot: snapshot,
               cur_from: Money::Currency.find(:BTC),
               cur_to: Money::Currency.find(:USD))
      end

      it 'includes CurrencyPairSupport module' do
        expect(ExternalRate.include?(CurrencyPairSupport)).to be true
      end

      it 'responds to currency_pair' do
        expect(rate).to respond_to(:currency_pair)
      end
    end
  end
end
