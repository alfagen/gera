# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExchangeRatesRepository do
    subject(:repository) { described_class.new }

    let!(:exchange_rate) { create(:gera_exchange_rate) }

    describe '#find_by_direction' do
      let(:direction) do
        double('Direction',
               ps_from_id: exchange_rate.ps_from_id,
               ps_to_id: exchange_rate.ps_to_id)
      end

      it 'returns exchange rate for direction' do
        expect(repository.find_by_direction(direction)).to eq(exchange_rate)
      end

      it 'returns nil for non-existent direction' do
        non_existent = double('Direction', ps_from_id: -1, ps_to_id: -1)
        expect(repository.find_by_direction(non_existent)).to be_nil
      end
    end

    describe '#get_matrix' do
      it 'returns a hash matrix of exchange rates' do
        matrix = repository.get_matrix
        expect(matrix).to be_a(Hash)
        expect(matrix[exchange_rate.ps_from_id][exchange_rate.ps_to_id]).to eq(exchange_rate)
      end

      it 'memoizes the matrix' do
        expect(repository.get_matrix).to eq(repository.get_matrix)
      end
    end
  end
end
