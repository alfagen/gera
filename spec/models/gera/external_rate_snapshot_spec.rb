# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExternalRateSnapshot do
    describe 'associations' do
      let(:rate_source) { create(:rate_source_exmo) }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }

      it 'belongs to rate_source' do
        expect(snapshot).to respond_to(:rate_source)
        expect(snapshot.rate_source).to eq(rate_source)
      end

      it 'has many external_rates' do
        expect(snapshot).to respond_to(:external_rates)
      end
    end

    describe 'scopes' do
      let(:rate_source) { create(:rate_source_exmo) }
      let!(:older_snapshot) { create(:external_rate_snapshot, rate_source: rate_source, actual_for: 1.day.ago) }
      let!(:newer_snapshot) { create(:external_rate_snapshot, rate_source: rate_source, actual_for: Time.zone.now) }

      describe '.ordered' do
        it 'orders by actual_for desc' do
          expect(ExternalRateSnapshot.ordered.first).to eq(newer_snapshot)
        end
      end

      describe '.last_actuals_by_rate_sources' do
        let(:another_source) { create(:rate_source_cbr) }
        let!(:another_snapshot) { create(:external_rate_snapshot, rate_source: another_source) }

        it 'returns one snapshot per rate source' do
          result = ExternalRateSnapshot.last_actuals_by_rate_sources
          expect(result.pluck(:rate_source_id).uniq.count).to eq(result.count)
        end
      end
    end

    describe 'callbacks' do
      let(:rate_source) { create(:rate_source_exmo) }

      describe 'before_save' do
        it 'sets actual_for if blank' do
          snapshot = ExternalRateSnapshot.new(rate_source: rate_source)
          snapshot.save!
          expect(snapshot.actual_for).to be_present
        end

        it 'does not override actual_for if set' do
          specific_time = 1.hour.ago
          snapshot = ExternalRateSnapshot.new(rate_source: rate_source, actual_for: specific_time)
          snapshot.save!
          expect(snapshot.actual_for).to be_within(1.second).of(specific_time)
        end
      end
    end

    describe '#to_s' do
      let(:rate_source) { create(:rate_source_exmo, title: 'EXMO') }
      let(:snapshot) { create(:external_rate_snapshot, rate_source: rate_source) }

      it 'returns formatted string' do
        expect(snapshot.to_s).to include('snapshot')
        expect(snapshot.to_s).to include(snapshot.id.to_s)
      end
    end
  end
end
