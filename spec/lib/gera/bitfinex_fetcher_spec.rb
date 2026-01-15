# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BitfinexFetcher do
    describe '#perform' do
      let(:api_response) do
        [
          ['tBTCUSD', 50000.0, 1.5, 50001.0, 2.0, 100.0, 0.01, 50000.5, 1000.0, 51000.0, 49000.0],
          ['tETHUSD', 3000.0, 10.0, 3001.0, 15.0, 50.0, 0.02, 3000.5, 5000.0, 3100.0, 2900.0],
          ['tUNKNOWN', 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]
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

      context 'when price is zero' do
        let(:api_response) do
          [
            ['tBTCUSD', 50000.0, 1.5, 50001.0, 2.0, 100.0, 0.01, 0.0, 1000.0, 51000.0, 49000.0]
          ].to_json
        end

        it 'skips pairs with zero prices' do
          result = subject.perform
          expect(result).to be_empty
        end
      end

      context 'with VCR cassette' do
        it 'fetches rates from Bitfinex API' do
          VCR.use_cassette 'Gera_BitfinexFetcher/1_1', allow_playback_repeats: true do
            result = subject.perform
            expect(result).to be_a(Hash)
          end
        end
      end
    end

    describe '#find_cur_from' do
      it 'finds currency from symbol with t prefix' do
        # tBTCUSD should find BTC
        result = subject.send(:find_cur_from, 'tBTCUSD')
        expect(result).to eq(Money::Currency.find(:BTC))
      end

      it 'returns nil for unsupported currencies' do
        result = subject.send(:find_cur_from, 'tUNKNOWN123')
        expect(result).to be_nil
      end
    end

    describe '#price_is_missed?' do
      it 'returns true when rate[7] is zero' do
        rate = [nil, nil, nil, nil, nil, nil, nil, 0.0]
        expect(subject.send(:price_is_missed?, rate: rate)).to be true
      end

      it 'returns false when rate[7] is non-zero' do
        rate = [nil, nil, nil, nil, nil, nil, nil, 100.0]
        expect(subject.send(:price_is_missed?, rate: rate)).to be false
      end
    end

    describe '#supported_currencies' do
      it 'returns currencies from RateSourceBitfinex' do
        expect(subject.send(:supported_currencies)).to eq(RateSourceBitfinex.supported_currencies)
      end
    end
  end
end
