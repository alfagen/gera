# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe DirectionRatesRepository do
    subject(:repository) { described_class.new }

    let!(:direction_rate_snapshot) { create(:direction_rate_snapshot) }
    let!(:exchange_rate) { create(:gera_exchange_rate) }
    let!(:currency_rate_snapshot) { create(:currency_rate_snapshot) }
    let!(:currency_rate) do
      create(:currency_rate,
             snapshot: currency_rate_snapshot,
             cur_from: exchange_rate.payment_system_from.currency,
             cur_to: exchange_rate.payment_system_to.currency)
    end
    # Create direction_rate with all values pre-set to avoid callback triggering external services
    let!(:direction_rate) do
      DirectionRate.create!(
        snapshot: direction_rate_snapshot,
        exchange_rate: exchange_rate,
        currency_rate: currency_rate,
        ps_from: exchange_rate.payment_system_from,
        ps_to: exchange_rate.payment_system_to,
        base_rate_value: currency_rate.rate_value,
        rate_percent: 5.0,
        rate_value: 57.0 # Setting rate_value (finite_rate) avoids calculate_rate callback
      )
    end

    describe '#snapshot' do
      it 'returns the last direction rate snapshot' do
        expect(repository.snapshot).to eq(direction_rate_snapshot)
      end

      it 'raises NoActualSnapshot when no snapshot exists' do
        DirectionRateSnapshot.delete_all
        new_repository = described_class.new
        expect { new_repository.snapshot }
          .to raise_error(DirectionRatesRepository::NoActualSnapshot)
      end
    end

    describe '#all' do
      it 'returns all direction rates from snapshot' do
        expect(repository.all).to include(direction_rate)
      end
    end

    describe '#find_direction_rate_by_exchange_rate_id' do
      it 'returns direction rate for exchange rate id' do
        expect(repository.find_direction_rate_by_exchange_rate_id(exchange_rate.id))
          .to eq(direction_rate)
      end

      it 'raises FinitRateNotFound for non-existent exchange rate id' do
        expect { repository.find_direction_rate_by_exchange_rate_id(-1) }
          .to raise_error(DirectionRatesRepository::FinitRateNotFound)
      end
    end

    describe '#get_by_direction' do
      let(:direction) do
        double('Direction',
               ps_from_id: direction_rate.ps_from_id,
               ps_to_id: direction_rate.ps_to_id)
      end

      it 'returns direction rate for direction' do
        expect(repository.get_by_direction(direction)).to eq(direction_rate)
      end

      it 'returns nil for non-existent direction' do
        non_existent = double('Direction', ps_from_id: -1, ps_to_id: -1)
        expect(repository.get_by_direction(non_existent)).to be_nil
      end
    end

    describe '#get_matrix' do
      it 'returns a hash matrix of direction rates' do
        matrix = repository.get_matrix
        expect(matrix).to be_a(Hash)
        expect(matrix[direction_rate.ps_from_id][direction_rate.ps_to_id]).to eq(direction_rate)
      end
    end
  end
end
