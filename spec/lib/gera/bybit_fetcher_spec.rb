# frozen_string_literal: true

require 'spec_helper'
require 'gera/bybit_fetcher'

module Gera
  RSpec.describe BybitFetcher do
    describe '#perform' do
      let(:api_response) do
        {
          'result' => {
            'items' => [
              { 'tokenId' => 'USDT', 'currencyId' => 'RUB', 'price' => '95' },
              { 'tokenId' => 'USDT', 'currencyId' => 'RUB', 'price' => '94' },
              { 'tokenId' => 'USDT', 'currencyId' => 'RUB', 'price' => '93' }
            ]
          }
        }
      end

      let(:http_response) do
        instance_double(RestClient::Response, code: 200, body: api_response.to_json)
      end

      before do
        allow(RestClient::Request).to receive(:execute).and_return(http_response)
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
          supported = RateSourceBybit.supported_currencies.map(&:iso_code)
          expect(supported).to include(pair.cur_from.iso_code)
          expect(supported).to include(pair.cur_to.iso_code)
        end
      end

      context 'when no rates available' do
        let(:api_response) do
          { 'result' => { 'items' => [] } }
        end

        it 'raises Error' do
          expect { subject.perform }.to raise_error(BybitFetcher::Error, 'No rates')
        end
      end

      context 'when only one rate available' do
        let(:api_response) do
          {
            'result' => {
              'items' => [
                { 'tokenId' => 'USDT', 'currencyId' => 'RUB', 'price' => '95' }
              ]
            }
          }
        end

        it 'raises Error' do
          expect { subject.perform }.to raise_error(BybitFetcher::Error, 'No rates')
        end
      end

      context 'when two rates available' do
        let(:api_response) do
          {
            'result' => {
              'items' => [
                { 'tokenId' => 'USDT', 'currencyId' => 'RUB', 'price' => '95' },
                { 'tokenId' => 'USDT', 'currencyId' => 'RUB', 'price' => '94' }
              ]
            }
          }
        end

        it 'uses second rate' do
          result = subject.perform
          expect(result.values.first['price']).to eq('94')
        end
      end
    end

    describe '#supported_currencies' do
      it 'returns currencies from RateSourceBybit' do
        expect(subject.send(:supported_currencies)).to eq(RateSourceBybit.supported_currencies)
      end
    end

    describe '#params' do
      it 'returns params hash with tokenId USDT' do
        params = subject.send(:params)
        expect(params[:tokenId]).to eq('USDT')
      end

      it 'returns params hash with currencyId RUB' do
        params = subject.send(:params)
        expect(params[:currencyId]).to eq('RUB')
      end
    end
  end
end
