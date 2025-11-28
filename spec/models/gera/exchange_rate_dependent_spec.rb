# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gera::ExchangeRate, 'dependent delete_all' do
  before do
    allow(Gera::DirectionsRatesWorker).to receive(:perform_async)

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
    context 'with associated direction_rates' do
      let!(:exchange_rate) { create(:gera_exchange_rate) }
      let!(:direction_rate) { create(:gera_direction_rate, exchange_rate: exchange_rate) }

      it 'deletes associated direction_rates' do
        expect { exchange_rate.destroy }.to change(Gera::DirectionRate, :count).by(-1)
      end

      it 'does not raise foreign key constraint error' do
        expect { exchange_rate.destroy }.not_to raise_error
      end
    end

    context 'with multiple direction_rates' do
      let!(:exchange_rate) { create(:gera_exchange_rate) }

      before do
        3.times { create(:gera_direction_rate, exchange_rate: exchange_rate) }
      end

      it 'deletes all associated direction_rates' do
        expect { exchange_rate.destroy }.to change(Gera::DirectionRate, :count).by(-3)
      end
    end
  end

  describe '.destroy_all' do
    before do
      Gera::DirectionRate.delete_all
      Gera::ExchangeRate.delete_all

      er = create(:gera_exchange_rate)
      create(:gera_direction_rate, exchange_rate: er)
    end

    it 'deletes all exchange_rates and associated direction_rates' do
      expect { Gera::ExchangeRate.destroy_all }.not_to raise_error
      expect(Gera::ExchangeRate.count).to eq(0)
      expect(Gera::DirectionRate.count).to eq(0)
    end
  end
end
