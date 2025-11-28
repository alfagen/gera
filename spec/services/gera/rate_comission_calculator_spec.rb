# frozen_string_literal: true

require 'spec_helper'

module Gera
  # Extend PaymentSystem with auto_rate_settings for testing
  # This association is expected to be defined in the host application
  class PaymentSystem
    def auto_rate_settings
      # Return empty relation-like object
      @auto_rate_settings_stub ||= Class.new do
        def find_by(*)
          nil
        end
      end.new
    end
  end

  RSpec.describe RateComissionCalculator do
    let(:payment_system_from) { create(:gera_payment_system, currency: Money::Currency.find('USD')) }
    let(:payment_system_to) { create(:gera_payment_system, currency: Money::Currency.find('RUB')) }
    let(:exchange_rate) do
      create(:gera_exchange_rate,
             payment_system_from: payment_system_from,
             payment_system_to: payment_system_to)
    end

    subject(:calculator) do
      described_class.new(
        exchange_rate: exchange_rate,
        external_rates: external_rates
      )
    end

    let(:external_rates) { nil }

    describe '#auto_comission' do
      it 'returns calculated commission' do
        # Without real auto_rate_settings, auto_comission returns 0
        expect(calculator.auto_comission).to be_a(Numeric)
      end
    end

    describe '#auto_comission_by_reserve' do
      context 'when auto rates by reserve not ready' do
        it 'returns 0.0' do
          expect(calculator.auto_comission_by_reserve).to eq(0.0)
        end
      end
    end

    describe '#comission_by_base_rate' do
      context 'when auto rates by base rate not ready' do
        it 'returns 0.0' do
          expect(calculator.comission_by_base_rate).to eq(0.0)
        end
      end
    end

    describe '#auto_rate_by_base_from' do
      context 'when base rate checkpoints not ready' do
        it 'returns 0.0' do
          expect(calculator.auto_rate_by_base_from).to eq(0.0)
        end
      end
    end

    describe '#auto_rate_by_base_to' do
      context 'when base rate checkpoints not ready' do
        it 'returns 0.0' do
          expect(calculator.auto_rate_by_base_to).to eq(0.0)
        end
      end
    end

    describe '#auto_rate_by_reserve_from' do
      context 'when reserve checkpoints not ready' do
        it 'returns 0.0' do
          expect(calculator.auto_rate_by_reserve_from).to eq(0.0)
        end
      end
    end

    describe '#auto_rate_by_reserve_to' do
      context 'when reserve checkpoints not ready' do
        it 'returns 0.0' do
          expect(calculator.auto_rate_by_reserve_to).to eq(0.0)
        end
      end
    end

    describe '#current_base_rate' do
      context 'when same currencies' do
        let(:payment_system_to) { create(:gera_payment_system, currency: Money::Currency.find('USD')) }

        it 'returns 1.0' do
          expect(calculator.current_base_rate).to eq(1.0)
        end
      end

      context 'when different currencies with history' do
        let!(:history_interval) do
          # Use even 5-minute intervals as required by HistoryIntervalConcern
          base_time = Time.current.beginning_of_hour
          CurrencyRateHistoryInterval.create!(
            cur_from_id: exchange_rate.in_currency.local_id,
            cur_to_id: exchange_rate.out_currency.local_id,
            avg_rate: 75.5,
            min_rate: 74.0,
            max_rate: 77.0,
            interval_from: base_time,
            interval_to: base_time + 5.minutes
          )
        end

        it 'returns avg_rate from last history interval' do
          expect(calculator.current_base_rate).to eq(75.5)
        end
      end
    end

    describe '#average_base_rate' do
      context 'when same currencies' do
        let(:payment_system_to) { create(:gera_payment_system, currency: Money::Currency.find('USD')) }

        it 'returns 1.0' do
          expect(calculator.average_base_rate).to eq(1.0)
        end
      end
    end

    describe '#auto_comission_from' do
      it 'returns sum of reserve and base rate auto rates' do
        expect(calculator.auto_comission_from).to eq(0.0)
      end
    end

    describe '#auto_comission_to' do
      it 'returns sum of reserve and base rate auto rates' do
        expect(calculator.auto_comission_to).to eq(0.0)
      end
    end

    describe '#bestchange_delta' do
      it 'returns auto_comission_by_external_comissions' do
        expect(calculator.bestchange_delta).to eq(0)
      end
    end

    describe 'constants' do
      it 'defines AUTO_COMISSION_GAP' do
        expect(described_class::AUTO_COMISSION_GAP).to eq(0.01)
      end

      it 'defines NOT_ALLOWED_COMISSION_RANGE' do
        expect(described_class::NOT_ALLOWED_COMISSION_RANGE).to eq(0.7..1.4)
      end

      it 'defines EXCLUDED_PS_IDS' do
        expect(described_class::EXCLUDED_PS_IDS).to eq([54, 56])
      end
    end
  end
end
