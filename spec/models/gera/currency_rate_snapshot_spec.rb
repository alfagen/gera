# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateSnapshot do
    describe 'associations' do
      let(:mode_snapshot) { create(:currency_rate_mode_snapshot) }
      let(:snapshot) { create(:currency_rate_snapshot, currency_rate_mode_snapshot: mode_snapshot) }

      it 'has many rates' do
        expect(snapshot).to respond_to(:rates)
      end

      it 'belongs to currency_rate_mode_snapshot' do
        expect(snapshot).to respond_to(:currency_rate_mode_snapshot)
        expect(snapshot.currency_rate_mode_snapshot).to eq(mode_snapshot)
      end
    end

    describe '#currency_rates' do
      let(:mode_snapshot) { create(:currency_rate_mode_snapshot) }
      let(:snapshot) { create(:currency_rate_snapshot, currency_rate_mode_snapshot: mode_snapshot) }
      let!(:rate) { create(:currency_rate, snapshot: snapshot) }

      it 'returns rates' do
        expect(snapshot.currency_rates).to include(rate)
      end

      it 'is an alias for rates' do
        expect(snapshot.currency_rates).to eq(snapshot.rates)
      end
    end
  end
end
