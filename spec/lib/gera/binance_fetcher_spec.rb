# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BinanceFetcher do
    describe '#perform' do
      let(:api_response) do
        [
          { 'symbol' => 'BTCUSDT', 'bidPrice' => '50000.00', 'askPrice' => '50001.00' },
          { 'symbol' => 'ETHUSDT', 'bidPrice' => '3000.00', 'askPrice' => '3001.00' },
          { 'symbol' => 'UNKNOWN123', 'bidPrice' => '1.00', 'askPrice' => '1.01' }
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

      context 'with VCR cassette' do
        it 'fetches rates from Binance API' do
          VCR.use_cassette :binance_with_two_external_rates, allow_playback_repeats: true do
            result = subject.perform
            expect(result).to be_a(Hash)
          end
        end
      end

      context 'when price is zero' do
        let(:api_response) do
          [
            { 'symbol' => 'BTCUSDT', 'bidPrice' => '0.00000000', 'askPrice' => '50001.00' }
          ].to_json
        end

        it 'skips pairs with zero prices' do
          result = subject.perform
          expect(result).to be_empty
        end
      end
    end

    describe '#price_is_missed?' do
      it 'returns true when bidPrice is zero' do
        rate = { 'bidPrice' => '0.00000000', 'askPrice' => '1.00' }
        expect(subject.send(:price_is_missed?, rate: rate)).to be true
      end

      it 'returns true when askPrice is zero' do
        rate = { 'bidPrice' => '1.00', 'askPrice' => '0.00000000' }
        expect(subject.send(:price_is_missed?, rate: rate)).to be true
      end

      it 'returns false when both prices are non-zero' do
        rate = { 'bidPrice' => '1.00', 'askPrice' => '1.01' }
        expect(subject.send(:price_is_missed?, rate: rate)).to be false
      end
    end

    describe '#currency_name' do
      it 'returns DASH for DSH currency' do
        expect(subject.send(:currency_name, :DSH)).to eq('DASH')
      end

      it 'returns currency name as is for other currencies' do
        expect(subject.send(:currency_name, :BTC)).to eq('BTC')
      end
    end

    describe '#supported_currencies' do
      it 'returns currencies from RateSourceBinance' do
        expect(subject.send(:supported_currencies)).to eq(RateSourceBinance.supported_currencies)
      end
    end
  end
end
