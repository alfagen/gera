# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe DirectionsRatesWorker do
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
    end

    describe 'sidekiq_options' do
      it 'uses critical queue' do
        expect(described_class.sidekiq_options['queue']).to eq(:critical)
      end
    end

    describe 'Error constant' do
      it 'defines Error class' do
        expect(described_class::Error).to be < StandardError
      end
    end
  end
end
