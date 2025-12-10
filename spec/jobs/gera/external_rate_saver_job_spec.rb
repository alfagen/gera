# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExternalRateSaverJob do
    let!(:rate_source) { create(:rate_source_exmo) }
    let!(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }

    describe '#perform' do
      let(:currency_pair) { 'BTC/USD' }
      let(:rate) do
        {
          'value' => 50000.0,
          'source_class_name' => 'Gera::RateSourceExmo',
          'source_id' => rate_source.id
        }
      end
      let(:source_rates_count) { 1 }

      it 'creates an external rate' do
        expect {
          subject.perform(currency_pair, snapshot.id, rate, source_rates_count)
        }.to change(ExternalRate, :count).by(1)
      end

      it 'creates rate with correct attributes' do
        subject.perform(currency_pair, snapshot.id, rate, source_rates_count)

        external_rate = ExternalRate.last
        expect(external_rate.cur_from).to eq('BTC')
        expect(external_rate.cur_to).to eq('USD')
        expect(external_rate.rate_value).to eq(50000.0)
        expect(external_rate.source).to eq(rate_source)
        expect(external_rate.snapshot).to eq(snapshot)
      end

      context 'when snapshot is filled up' do
        before do
          # Create one external rate so total will be 2 (source_rates_count * 2)
          create(:external_rate, source: rate_source, snapshot: snapshot, cur_from: 'ETH', cur_to: 'BTC')
        end

        it 'updates actual_snapshot_id' do
          # source_rates_count = 1, so expected count is 2
          subject.perform(currency_pair, snapshot.id, rate, 1)
          expect(rate_source.reload.actual_snapshot_id).to eq(snapshot.id)
        end
      end
    end

    describe 'queue configuration' do
      it 'uses external_rates queue' do
        expect(described_class.queue_name).to eq('external_rates')
      end
    end
  end
end
