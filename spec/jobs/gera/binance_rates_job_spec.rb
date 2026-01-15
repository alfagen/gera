# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BinanceRatesJob do
    let!(:rate_source) { create(:rate_source_binance) }

    describe '#perform' do
      it 'uses BinanceFetcher to load rates' do
        mock_fetcher = instance_double(BinanceFetcher)
        allow(BinanceFetcher).to receive(:new).and_return(mock_fetcher)
        allow(mock_fetcher).to receive(:perform).and_return({})

        job = described_class.new
        job.perform

        expect(BinanceFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end

      context 'with VCR cassette' do
        it 'creates external rates from API response' do
          VCR.use_cassette :binance_with_two_external_rates, allow_playback_repeats: true do
            expect { described_class.new.perform }.to change(ExternalRateSnapshot, :count).by(1)
          end
        end
      end
    end

    describe '#rate_keys' do
      it 'returns bidPrice and askPrice keys' do
        job = described_class.new
        expect(job.send(:rate_keys)).to eq({ buy: 'bidPrice', sell: 'askPrice' })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceBinance' do
        job = described_class.new
        expect(job.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
