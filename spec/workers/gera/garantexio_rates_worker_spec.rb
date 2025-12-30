# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe GarantexioRatesWorker do
    let!(:rate_source) { create(:rate_source_garantexio) }

    describe '#perform' do
      it 'uses GarantexioFetcher to load rates' do
        mock_fetcher = instance_double(GarantexioFetcher)
        allow(GarantexioFetcher).to receive(:new).and_return(mock_fetcher)
        allow(mock_fetcher).to receive(:perform).and_return({})

        worker = described_class.new
        worker.perform

        expect(GarantexioFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end
    end

    describe '#rate_keys' do
      it 'returns last_price for both buy and sell' do
        worker = described_class.new
        expect(worker.send(:rate_keys)).to eq({ buy: 'last_price', sell: 'last_price' })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceGarantexio' do
        worker = described_class.new
        expect(worker.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
