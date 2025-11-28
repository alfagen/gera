# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExmoFetcher do
    describe '#perform' do
      let(:api_response) do
        {
          'BTC_USD' => { 'buy_price' => '50000', 'sell_price' => '50001' },
          'ETH_RUB' => { 'buy_price' => '300000', 'sell_price' => '300100' },
          'DASH_USD' => { 'buy_price' => '100', 'sell_price' => '101' }
        }.to_json
      end

      before do
        allow(subject).to receive(:open).and_return(double('io', read: api_response))
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

      it 'converts DASH to DSH' do
        result = subject.perform
        # DASH_USD should become DSH/USD pair
        dsh_pair = result.keys.find { |p| p.cur_from.iso_code == 'DSH' }
        expect(dsh_pair).not_to be_nil
      end

      context 'with VCR cassette' do
        it 'fetches rates from EXMO API' do
          VCR.use_cassette :exmo, allow_playback_repeats: true do
            result = subject.perform
            expect(result).to be_a(Hash)
          end
        end
      end

      context 'when API returns error' do
        let(:api_response) { { 'error' => 'Invalid request' }.to_json }

        it 'raises Error' do
          expect { subject.perform }.to raise_error(ExmoFetcher::Error)
        end
      end

      context 'when API returns non-hash' do
        let(:api_response) { [].to_json }

        it 'raises Error' do
          expect { subject.perform }.to raise_error(ExmoFetcher::Error, 'Result is not a hash')
        end
      end
    end

    describe '#split_currency_pair_keys' do
      it 'splits currency pair and converts DASH to DSH' do
        result = subject.send(:split_currency_pair_keys, 'DASH_USD')
        expect(result).to eq(%w[DSH USD])
      end

      it 'splits regular currency pair' do
        result = subject.send(:split_currency_pair_keys, 'BTC_USD')
        expect(result).to eq(%w[BTC USD])
      end
    end

    describe '#find_currency' do
      it 'finds currency by key' do
        result = subject.send(:find_currency, 'BTC')
        expect(result).to eq(Money::Currency.find(:BTC))
      end

      it 'returns nil for unknown currency' do
        result = subject.send(:find_currency, 'UNKNOWN123')
        expect(result).to be_nil
      end
    end
  end
end
