# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateMode do
    describe 'associations' do
      let(:snapshot) { create(:currency_rate_mode_snapshot) }
      let(:mode) { create(:currency_rate_mode, snapshot: snapshot) }

      it 'belongs to snapshot' do
        expect(mode).to respond_to(:snapshot)
        expect(mode.snapshot).to eq(snapshot)
      end

      it 'has many cross_rate_modes' do
        expect(mode).to respond_to(:cross_rate_modes)
      end
    end

    describe 'enums' do
      it 'defines mode enum' do
        expect(described_class.modes).to include('auto', 'cbr', 'cbr_avg', 'exmo', 'cross', 'bitfinex')
      end
    end

    describe '.default_for_pair' do
      let(:pair) { CurrencyPair.new('BTC/USD') }

      it 'creates new CurrencyRateMode with auto mode' do
        mode = described_class.default_for_pair(pair)
        expect(mode.mode).to eq('auto')
        expect(mode.new_record?).to be true
      end
    end

    describe '#to_s' do
      let(:snapshot) { create(:currency_rate_mode_snapshot) }
      let(:mode) { create(:currency_rate_mode, snapshot: snapshot, mode: :exmo) }

      it 'returns mode name for persisted record' do
        expect(mode.to_s).to eq('exmo')
      end

      it 'returns default for new auto mode record' do
        new_mode = described_class.new(mode: :auto)
        expect(new_mode.to_s).to eq('default')
      end
    end

    describe '#mode' do
      let(:snapshot) { create(:currency_rate_mode_snapshot) }
      let(:mode) { create(:currency_rate_mode, snapshot: snapshot, mode: :auto) }

      it 'returns inquiry object' do
        expect(mode.mode.auto?).to be true
        expect(mode.mode.exmo?).to be false
      end
    end

    describe 'nested attributes' do
      it 'accepts nested attributes for cross_rate_modes' do
        expect(described_class.nested_attributes_options).to have_key(:cross_rate_modes)
      end
    end
  end
end
