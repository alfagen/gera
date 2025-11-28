# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CryptomusRatesWorker do
    let!(:rate_source) { create(:rate_source_cryptomus) }

    # Stub CryptomusFetcher class which has external dependencies (PaymentServices)
    before do
      stub_const('Gera::CryptomusFetcher', Class.new do
        def perform
          {}
        end
      end)
    end

    describe '#perform' do
      it 'uses CryptomusFetcher to load rates' do
        mock_fetcher = double('CryptomusFetcher', perform: {})
        allow(Gera::CryptomusFetcher).to receive(:new).and_return(mock_fetcher)

        worker = described_class.new
        worker.perform

        expect(Gera::CryptomusFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end
    end

    describe '#rate_keys' do
      it 'returns course for both buy and sell' do
        worker = described_class.new
        expect(worker.send(:rate_keys)).to eq({ buy: 'course', sell: 'course' })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceCryptomus' do
        worker = described_class.new
        expect(worker.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
