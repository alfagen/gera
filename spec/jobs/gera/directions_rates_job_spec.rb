# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe DirectionsRatesJob do
    # Stub BestChange::Service which is defined in host app
    before do
      stub_const('BestChange::Service', Class.new do
        def initialize(exchange_rate:); end
        def rows_without_kassa; []; end
      end)
    end

    let!(:currency_rate_snapshot) { create(:currency_rate_snapshot) }
    let!(:payment_system_from) { create(:gera_payment_system, currency: Money::Currency.find('USD')) }
    let!(:payment_system_to) { create(:gera_payment_system, currency: Money::Currency.find('RUB')) }
    let!(:exchange_rate) do
      create(:gera_exchange_rate,
             payment_system_from: payment_system_from,
             payment_system_to: payment_system_to)
    end
    let!(:currency_rate) do
      create(:currency_rate,
             snapshot: currency_rate_snapshot,
             cur_from: Money::Currency.find('USD'),
             cur_to: Money::Currency.find('RUB'))
    end

    describe '#perform' do
      it 'creates a new DirectionRateSnapshot' do
        expect { subject.perform }.to change(DirectionRateSnapshot, :count).by(1)
      end

      it 'creates direction rates for each exchange rate' do
        expect { subject.perform }.to change(DirectionRate, :count).by_at_least(1)
      end

      it 'logs start and finish' do
        expect(subject).to receive(:logger).at_least(:twice).and_return(double(info: nil))
        subject.perform
      end

      it 'creates direction rate with correct attributes' do
        subject.perform
        direction_rate = DirectionRate.last

        expect(direction_rate.exchange_rate_id).to eq(exchange_rate.id)
        expect(direction_rate.currency_rate_id).to eq(currency_rate.id)
        expect(direction_rate.ps_from_id).to eq(payment_system_from.id)
        expect(direction_rate.ps_to_id).to eq(payment_system_to.id)
        expect(direction_rate.base_rate_value).to eq(currency_rate.rate_value)
        expect(direction_rate.rate_percent).to be_present
        expect(direction_rate.rate_value).to be_present
      end

      context 'with multiple exchange rates' do
        let!(:payment_system_eur) { create(:gera_payment_system, currency: Money::Currency.find('EUR')) }
        let!(:exchange_rate2) do
          create(:gera_exchange_rate,
                 payment_system_from: payment_system_to,
                 payment_system_to: payment_system_eur)
        end
        let!(:currency_rate2) do
          create(:currency_rate,
                 snapshot: currency_rate_snapshot,
                 cur_from: Money::Currency.find('RUB'),
                 cur_to: Money::Currency.find('EUR'),
                 currency_pair: Gera::CurrencyPair.new(Money::Currency.find('RUB'), Money::Currency.find('EUR')))
        end

        it 'creates direction rates for all exchange rates with matching currency rates' do
          expect { subject.perform }.to change(DirectionRate, :count).by(2)
        end

        it 'uses batch insert (single SQL INSERT)' do
          # Verify that insert_all! is called instead of individual creates
          expect(DirectionRate).to receive(:insert_all!).once.and_call_original
          subject.perform
        end
      end

      context 'when currency rate is missing for an exchange rate' do
        let!(:payment_system_btc) { create(:gera_payment_system, currency: Money::Currency.find('BTC')) }
        let!(:exchange_rate_no_currency_rate) do
          create(:gera_exchange_rate,
                 payment_system_from: payment_system_from,
                 payment_system_to: payment_system_btc)
        end

        it 'skips exchange rates without matching currency rates' do
          expect { subject.perform }.to change(DirectionRate, :count).by(1)
        end
      end
    end

    describe 'queue configuration' do
      it 'uses critical queue' do
        expect(described_class.queue_name).to eq('critical')
      end
    end

    describe 'Error constant' do
      it 'defines Error class' do
        expect(described_class::Error).to be < StandardError
      end
    end
  end
end
