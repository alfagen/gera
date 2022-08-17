# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BinanceRatesWorker do
    let!(:rate_source) { create(:rate_source_binance) }

    it 'should approve new snapshot if it has the same count of external rates' do
      actual_snapshot = create(:external_rate_snapshot, rate_source: rate_source)
      actual_snapshot.external_rates << create(:external_rate, source: rate_source, snapshot: actual_snapshot)
      actual_snapshot.external_rates << create(:inverse_external_rate, source: rate_source, snapshot: actual_snapshot)
      rate_source.update_column(:actual_snapshot_id, actual_snapshot.id)

      expect(rate_source.actual_snapshot_id).to eq(actual_snapshot.id)
      VCR.use_cassette :binance_with_two_external_rates do
        expect(BinanceRatesWorker.new.perform).to be_truthy
      end
      expect(rate_source.reload.actual_snapshot_id).not_to eq(actual_snapshot.id)
    end

    it 'should not approve new snapshot if it has different count of external rates' do
      actual_snapshot = create(:external_rate_snapshot, rate_source: rate_source)
      actual_snapshot.external_rates << create(:external_rate, source: rate_source, snapshot: actual_snapshot)
      rate_source.update_column(:actual_snapshot_id, actual_snapshot.id)

      expect(rate_source.actual_snapshot_id).to eq(actual_snapshot.id)
      VCR.use_cassette :binance_with_two_external_rates do
        expect(BinanceRatesWorker.new.perform).to be_truthy
      end
      expect(rate_source.reload.actual_snapshot_id).to eq(actual_snapshot.id)
    end
  end
end
