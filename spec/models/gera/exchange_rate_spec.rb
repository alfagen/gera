# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExchangeRate do
    before do
      allow(DirectionsRatesWorker).to receive(:perform_async)
    end
    subject { create :gera_exchange_rate }
    it { expect(subject).to be_persisted }

    describe '.available scope' do
      it 'includes same-to-same direction (PIR-076)' do
        ps = create(:gera_payment_system, income_enabled: true, outcome_enabled: true)
        er = create(:gera_exchange_rate, payment_system_from: ps, payment_system_to: ps)

        expect(Gera::ExchangeRate.available).to include(er)
      end
    end

    describe '#autorate_calculator_class' do
      context 'when calculator_type is legacy' do
        before { subject.calculator_type = 'legacy' }

        it 'returns AutorateCalculators::Legacy' do
          expect(subject.autorate_calculator_class).to eq(AutorateCalculators::Legacy)
        end
      end

      context 'when calculator_type is position_aware' do
        before { subject.calculator_type = 'position_aware' }

        it 'returns AutorateCalculators::PositionAware' do
          expect(subject.autorate_calculator_class).to eq(AutorateCalculators::PositionAware)
        end
      end

      context 'when calculator_type is nil' do
        before { subject.calculator_type = nil }

        it 'defaults to AutorateCalculators::Legacy' do
          expect(subject.autorate_calculator_class).to eq(AutorateCalculators::Legacy)
        end
      end

      context 'when calculator_type is unknown' do
        it 'raises ArgumentError' do
          subject.calculator_type = 'unknown'
          expect { subject.autorate_calculator_class }.to raise_error(ArgumentError, /Unknown calculator_type/)
        end
      end
    end
  end
end
