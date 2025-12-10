# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BybitRatesJob do
    let!(:rate_source) { create(:rate_source_bybit) }

    # Stub BybitFetcher class which may have external dependencies
    before do
      stub_const('Gera::BybitFetcher', Class.new do
        def perform
          {}
        end
      end)
    end

    describe '#perform' do
      it 'uses BybitFetcher to load rates' do
        mock_fetcher = double('BybitFetcher', perform: {})
        allow(Gera::BybitFetcher).to receive(:new).and_return(mock_fetcher)

        job = described_class.new
        job.perform

        expect(Gera::BybitFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end
    end

    describe '#rate_keys' do
      it 'returns price for both buy and sell' do
        job = described_class.new
        expect(job.send(:rate_keys)).to eq({ buy: 'price', sell: 'price' })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceBybit' do
        # rate_source method does RateSourceBybit.get! which requires DB record
        job = described_class.new
        expect(job.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
