# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gera::PaymentSystem, 'dependent delete_all' do
  before do
    allow(Gera::DirectionsRatesJob).to receive(:perform_later)

    # Mock BestChange::Service to avoid dependency issues
    best_change_service_class = Class.new do
      def initialize(exchange_rate:); end

      def rows_without_kassa
        []
      end
    end
    stub_const('BestChange::Service', best_change_service_class)
  end

  describe '#destroy' do
    context 'with associated exchange_rates' do
      let!(:payment_system) { create(:gera_payment_system) }
      let!(:other_ps) { create(:gera_payment_system) }

      before do
        # Clear auto-created exchange_rates from after_create callback
        Gera::ExchangeRate.delete_all
      end

      let!(:exchange_rate_as_income) do
        create(:gera_exchange_rate,
               payment_system_from: payment_system,
               payment_system_to: other_ps)
      end

      let!(:exchange_rate_as_outcome) do
        create(:gera_exchange_rate,
               payment_system_from: other_ps,
               payment_system_to: payment_system)
      end

      it 'deletes exchange_rates where payment_system is income or outcome' do
        expect(Gera::ExchangeRate.count).to eq(2)
        expect { payment_system.destroy }.to change(Gera::ExchangeRate, :count).by(-2)
      end

      it 'does not raise foreign key constraint error' do
        expect { payment_system.destroy }.not_to raise_error
      end
    end

    context 'with associated direction_rates' do
      let!(:payment_system) { create(:gera_payment_system) }
      let!(:other_ps) { create(:gera_payment_system) }

      before do
        Gera::ExchangeRate.delete_all
      end

      let!(:exchange_rate) do
        create(:gera_exchange_rate,
               payment_system_from: payment_system,
               payment_system_to: other_ps)
      end

      let!(:direction_rate) do
        create(:gera_direction_rate, exchange_rate: exchange_rate)
      end

      it 'deletes associated direction_rates through exchange_rate cascade' do
        expect { payment_system.destroy }.to change(Gera::DirectionRate, :count).by(-1)
      end
    end
  end

  describe '.destroy_all' do
    before do
      Gera::PaymentSystem.delete_all
      Gera::ExchangeRate.delete_all
      Gera::DirectionRate.delete_all

      ps1 = create(:gera_payment_system)
      ps2 = create(:gera_payment_system)
      Gera::ExchangeRate.delete_all # Clear auto-created
      create(:gera_exchange_rate, payment_system_from: ps1, payment_system_to: ps2)
    end

    it 'deletes all payment_systems and associated records' do
      expect { Gera::PaymentSystem.destroy_all }.not_to raise_error
      expect(Gera::PaymentSystem.count).to eq(0)
      expect(Gera::ExchangeRate.count).to eq(0)
    end
  end
end
