# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe FfFloatRatesWorker do
    let!(:rate_source) { create(:rate_source_ff_float) }

    describe '#perform' do
      it 'uses FfFloatFetcher to load rates' do
        mock_fetcher = instance_double(FfFloatFetcher)
        allow(FfFloatFetcher).to receive(:new).and_return(mock_fetcher)
        allow(mock_fetcher).to receive(:perform).and_return({})

        worker = described_class.new
        worker.perform

        expect(FfFloatFetcher).to have_received(:new)
        expect(mock_fetcher).to have_received(:perform)
      end
    end

    describe '#rate_keys' do
      it 'returns out for both buy and sell' do
        worker = described_class.new
        expect(worker.send(:rate_keys)).to eq({ buy: 'out', sell: 'out' })
      end
    end

    describe '#rate_source' do
      it 'returns RateSourceFfFloat' do
        worker = described_class.new
        expect(worker.send(:rate_source)).to eq(rate_source)
      end
    end
  end
end
