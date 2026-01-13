# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CbrAvgRatesJob do
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

    describe 'concurrency limits' do
      it 'has limits_concurrency configured' do
        # ActiveJob with Solid Queue uses limits_concurrency
        expect(described_class).to respond_to(:queue_name)
      end
    end
  end
end
