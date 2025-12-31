# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExchangeRateUpdaterJob do
    # Stub Yabeda metrics which may not be configured in test
    before do
      yabeda_exchange = double('yabeda_exchange')
      allow(yabeda_exchange).to receive(:exchange_rate_touch_count).and_return(
        double('counter', increment: nil)
      )
      stub_const('Yabeda', double('Yabeda', exchange: yabeda_exchange))
    end

    let!(:exchange_rate) { create(:gera_exchange_rate) }

    describe '#perform' do
      let(:attributes) { { 'is_enabled' => false } }

      it 'updates exchange rate with given attributes' do
        expect {
          subject.perform(exchange_rate.id, attributes)
        }.to change { exchange_rate.reload.is_enabled }.from(true).to(false)
      end

      it 'increments yabeda metric' do
        expect(Yabeda.exchange.exchange_rate_touch_count).to receive(:increment)

        subject.perform(exchange_rate.id, attributes)
      end

      context 'with non-existent exchange rate' do
        it 'does not raise error' do
          expect {
            subject.perform(-1, attributes)
          }.not_to raise_error
        end
      end
    end

    describe 'queue configuration' do
      it 'uses exchange_rates queue' do
        expect(described_class.queue_name).to eq('exchange_rates')
      end
    end
  end
end
