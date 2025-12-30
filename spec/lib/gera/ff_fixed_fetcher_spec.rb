# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe FfFixedFetcher do
    describe '#perform' do
      let(:parsed_rates) do
        [
          { from: 'BTC', to: 'USDT', in: 1.0, out: 50000.0, amount: 1.0, tofee: '0', minamount: '0.001', maxamount: '10' },
          { from: 'BNB', to: 'USDT', in: 1.0, out: 300.0, amount: 1.0, tofee: '0', minamount: '0.1', maxamount: '100' },
          { from: 'UNKNOWN', to: 'XXX', in: 1.0, out: 1.0, amount: 1.0, tofee: '0', minamount: '1', maxamount: '100' }
        ]
      end

      before do
        allow(subject).to receive(:rates).and_return(parsed_rates)
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

      it 'converts BSC to BNB' do
        rates_with_bsc = [
          { from: 'BSC', to: 'USDT', in: 1.0, out: 300.0, amount: 1.0, tofee: '0', minamount: '0.1', maxamount: '100' }
        ]
        allow(subject).to receive(:rates).and_return(rates_with_bsc)

        result = subject.perform
        bnb_pair = result.keys.find { |p| p.cur_from.iso_code == 'BNB' || p.cur_to.iso_code == 'BNB' }
        expect(bnb_pair).not_to be_nil
      end

      it 'filters unsupported currencies' do
        result = subject.perform
        result.each_key do |pair|
          supported = RateSourceFfFixed.supported_currencies.map(&:iso_code)
          expect(supported).to include(pair.cur_from.iso_code)
          expect(supported).to include(pair.cur_to.iso_code)
        end
      end

      it 'does not add reverse pair if direct pair exists' do
        rates_with_reverse = [
          { from: 'BTC', to: 'USDT', in: 1.0, out: 50000.0, amount: 1.0, tofee: '0', minamount: '0.001', maxamount: '10' },
          { from: 'USDT', to: 'BTC', in: 50000.0, out: 1.0, amount: 50000.0, tofee: '0', minamount: '100', maxamount: '1000000' }
        ]
        allow(subject).to receive(:rates).and_return(rates_with_reverse)

        result = subject.perform
        # Should only have one pair (not both direct and reverse)
        pairs = result.keys.map { |p| [p.cur_from.iso_code, p.cur_to.iso_code].sort }
        expect(pairs.uniq.size).to eq(pairs.size)
      end

      it 'includes rate data with correct keys' do
        result = subject.perform
        next if result.empty?

        rate = result.values.first
        expect(rate).to include('from', 'to', 'in', 'out', 'amount')
      end
    end

    describe '#supported_currencies' do
      it 'returns currencies from RateSourceFfFixed' do
        expect(subject.send(:supported_currencies)).to eq(RateSourceFfFixed.supported_currencies)
      end
    end
  end
end
