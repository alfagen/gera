# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateModeSnapshot do
    describe 'associations' do
      let(:snapshot) { create(:currency_rate_mode_snapshot) }

      it 'has many currency_rate_modes' do
        expect(snapshot).to respond_to(:currency_rate_modes)
      end
    end

    describe 'enums' do
      it 'defines status enum' do
        expect(described_class.statuses).to include('draft', 'active', 'deactive')
      end
    end

    describe 'scopes' do
      let!(:active) { create(:currency_rate_mode_snapshot, status: :active) }
      let!(:draft) { create(:currency_rate_mode_snapshot, status: :draft) }

      describe '.ordered' do
        it 'orders by status desc and created_at desc' do
          result = CurrencyRateModeSnapshot.ordered
          expect(result.first.status).to eq('active')
        end
      end
    end

    describe 'callbacks' do
      describe 'before_validation' do
        it 'sets title from current time if blank' do
          snapshot = CurrencyRateModeSnapshot.new
          snapshot.valid?
          expect(snapshot.title).to be_present
        end
      end
    end

    describe '#create_modes!' do
      let(:snapshot) { create(:currency_rate_mode_snapshot) }

      it 'creates modes for all currency pairs' do
        expect {
          snapshot.create_modes!
        }.to change { snapshot.currency_rate_modes.count }.from(0)
      end

      it 'returns self' do
        expect(snapshot.create_modes!).to eq(snapshot)
      end
    end

    describe 'nested attributes' do
      it 'accepts nested attributes for currency_rate_modes' do
        expect(described_class.nested_attributes_options).to have_key(:currency_rate_modes)
      end
    end
  end
end
