# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CbrAvgRatesWorker do
    let!(:cbr_avg_source) { create(:rate_source_cbr_avg) }
    let!(:cbr_source) { create(:rate_source_cbr) }

    describe '#perform' do
      context 'with empty available_pairs' do
        before do
          # Stub the instance methods instead of class methods
          allow_any_instance_of(RateSourceCbrAvg).to receive(:available_pairs).and_return([])
        end

        it 'creates a new snapshot' do
          expect { subject.perform }.to change(ExternalRateSnapshot, :count).by(1)
        end

        it 'updates actual_snapshot_id' do
          subject.perform
          expect(cbr_avg_source.reload.actual_snapshot_id).not_to be_nil
        end
      end
    end

    describe 'sidekiq_options' do
      it 'uses until_executed lock' do
        expect(described_class.sidekiq_options['lock']).to eq(:until_executed)
      end
    end
  end
end
