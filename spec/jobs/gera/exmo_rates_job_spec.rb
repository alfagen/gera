# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExmoRatesJob do
    let!(:rate_source) { create(:rate_source_exmo) }

    describe '#perform' do
      it 'uses ExmoFetcher to load rates' do
        mock_fetcher = instance_double(ExmoFetcher)
        allow(ExmoFetcher).to receive(:new).and_return(mock_fetcher)
        allow(mock_fetcher).to receive(:perform).and_return({})

        job = described_class.new
        job.perform

        expect(ExmoFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end
    end

    describe '#rate_keys' do
      it 'returns buy_price and sell_price keys' do
        job = described_class.new
        expect(job.send(:rate_keys)).to eq({ buy: 'buy_price', sell: 'sell_price' })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceExmo' do
        job = described_class.new
        expect(job.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
