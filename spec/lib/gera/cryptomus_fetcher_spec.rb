# frozen_string_literal: true

require 'spec_helper'

# Stub PaymentServices::Base::Client before CryptomusFetcher is loaded
# This is necessary because CryptomusFetcher extends this class from host app
module PaymentServices
  module Base
    class Client
      def http_request(url:, method:, body: nil, headers: {})
        ''
      end

      def safely_parse(response)
        JSON.parse(response) rescue {}
      end
    end
  end
end unless defined?(PaymentServices::Base::Client)

# Now require the fetcher
require 'gera/cryptomus_fetcher'

module Gera
  RSpec.describe CryptomusFetcher do
    describe '#perform' do
      let(:btc_rates) do
        [
          { 'from' => 'BTC', 'to' => 'USD', 'course' => '50000' },
          { 'from' => 'BTC', 'to' => 'RUB', 'course' => '5000000' }
        ]
      end

      let(:eth_rates) do
        [
          { 'from' => 'ETH', 'to' => 'USD', 'course' => '3000' },
          { 'from' => 'ETH', 'to' => 'RUB', 'course' => '300000' }
        ]
      end

      before do
        allow(subject).to receive(:rate).with(currency: 'BTC').and_return(btc_rates)
        allow(subject).to receive(:rate).with(currency: 'DASH').and_return([])
        allow(subject).to receive(:rate).with(currency: anything).and_return([])
        # Override to return only BTC for simplicity
        allow(RateSourceCryptomus).to receive(:supported_currencies).and_return(
          [Money::Currency.find(:BTC), Money::Currency.find(:RUB), Money::Currency.find(:USD)]
        )
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
          supported = RateSourceCryptomus.supported_currencies.map(&:iso_code)
          expect(supported).to include(pair.cur_to.iso_code)
        end
      end

      it 'converts DASH to DSH' do
        # Create a subject with stubbed rates method that returns DASH data
        dsh_rates = [{ 'from' => 'DASH', 'to' => 'USD', 'course' => '100' }]
        allow(subject).to receive(:rates).and_return(dsh_rates)

        result = subject.perform
        dsh_pair = result.keys.find { |p| p.cur_from.iso_code == 'DSH' }
        expect(dsh_pair).not_to be_nil
      end
    end

    describe '#supported_currencies' do
      before do
        allow(RateSourceCryptomus).to receive(:supported_currencies).and_call_original
      end

      it 'returns currencies from RateSourceCryptomus' do
        expect(subject.send(:supported_currencies)).to eq(RateSourceCryptomus.supported_currencies)
      end
    end

    describe '#build_headers' do
      it 'returns headers with Content-Type' do
        headers = subject.send(:build_headers)
        expect(headers['Content-Type']).to eq('application/json')
      end
    end
  end
end
