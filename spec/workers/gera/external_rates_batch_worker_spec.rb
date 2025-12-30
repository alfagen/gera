# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExternalRatesBatchWorker do
    let!(:rate_source) { create(:rate_source_exmo) }
    let!(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }

    describe '#perform' do
      let(:rates) do
        {
          'BTC/USD' => { 'buy' => 50000.0, 'sell' => 50100.0 },
          'ETH/USD' => { 'buy' => 3000.0, 'sell' => 3010.0 }
        }
      end

      it 'creates external rates for each currency pair' do
        expect {
          subject.perform(snapshot.id, rate_source.id, rates)
        }.to change(ExternalRate, :count).by(4) # 2 pairs * 2 (buy + inverse)
      end

      it 'updates rate_source actual_snapshot_id' do
        subject.perform(snapshot.id, rate_source.id, rates)
        expect(rate_source.reload.actual_snapshot_id).to eq(snapshot.id)
      end

      context 'with symbol keys' do
        let(:rates) do
          {
            'BTC/USD' => { buy: 50000.0, sell: 50100.0 }
          }
        end

        it 'handles symbol keys correctly' do
          expect {
            subject.perform(snapshot.id, rate_source.id, rates)
          }.to change(ExternalRate, :count).by(2)
        end
      end

      context 'with invalid rates' do
        let(:rates) do
          {
            'BTC/USD' => { 'buy' => nil, 'sell' => 50100.0 },
            'ETH/USD' => { 'buy' => 0, 'sell' => 3010.0 },
            'LTC/USD' => { 'buy' => -1, 'sell' => 100.0 }
          }
        end

        it 'skips invalid rates' do
          expect {
            subject.perform(snapshot.id, rate_source.id, rates)
          }.not_to change(ExternalRate, :count)
        end
      end

      context 'with empty rates' do
        let(:rates) { {} }

        it 'still updates actual_snapshot_id' do
          subject.perform(snapshot.id, rate_source.id, rates)
          expect(rate_source.reload.actual_snapshot_id).to eq(snapshot.id)
        end
      end
    end
  end
end
