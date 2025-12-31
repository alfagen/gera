# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BitfinexRatesJob do
    let!(:rate_source) { create(:rate_source_bitfinex) }

    describe '#perform' do
      it 'uses BitfinexFetcher to load rates' do
        mock_fetcher = instance_double(BitfinexFetcher)
        allow(BitfinexFetcher).to receive(:new).and_return(mock_fetcher)
        allow(mock_fetcher).to receive(:perform).and_return({})

        job = described_class.new
        job.perform

        expect(BitfinexFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end
    end

    describe '#rate_keys' do
      it 'returns array index 7 for both buy and sell' do
        job = described_class.new
        expect(job.send(:rate_keys)).to eq({ buy: 7, sell: 7 })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceBitfinex' do
        job = described_class.new
        expect(job.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
