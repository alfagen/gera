# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe GarantexioFetcher do
    describe '#perform' do
      let(:api_response) do
        [
          { 'BTC_RUB' => { 'last_price' => '5000000', 'base_volume' => '10' } },
          { 'USDT_RUB' => { 'last_price' => '95', 'base_volume' => '1000' } },
          { 'UNKNOWN_XXX' => { 'last_price' => '1', 'base_volume' => '1' } }
        ].to_json
      end

      let(:response) { double('response', code: 200, body: api_response) }

      before do
        allow(RestClient::Request).to receive(:execute).and_return(response)
      end

      it 'returns hash of currency pairs to rates' do
        result = subject.perform
        expect(result).to be_a(Hash)
      end

      it 'creates CurrencyPair keys' do
        result = subject.perform
        result.each_key do |key|
          expect(key).to be_a(CurrencyPair)
        end
      end

      it 'filters only supported currencies' do
        result = subject.perform
        result.each_key do |pair|
          supported = RateSourceGarantexio.supported_currencies.map(&:iso_code)
          expect(supported).to include(pair.cur_from.iso_code)
          expect(supported).to include(pair.cur_to.iso_code)
        end
      end

      context 'when API returns error' do
        before do
          allow(RestClient::Request).to receive(:execute).and_raise(RestClient::ExceptionWithResponse)
        end

        it 'raises error' do
          expect { subject.perform }.to raise_error(RestClient::ExceptionWithResponse)
        end
      end
    end

    describe '#supported_currencies' do
      it 'returns currencies from RateSourceGarantexio' do
        expect(subject.send(:supported_currencies)).to eq(RateSourceGarantexio.supported_currencies)
      end
    end
  end
end
