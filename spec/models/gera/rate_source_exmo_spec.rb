# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceExmo do
    describe '.supported_currencies' do
      it 'returns array of Money::Currency objects' do
        currencies = described_class.supported_currencies
        expect(currencies).to all(be_a(Money::Currency))
      end

      it 'includes BTC' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('BTC')
      end

      it 'includes USD' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('USD')
      end

      it 'includes RUB' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('RUB')
      end
    end

    describe '.available_pairs' do
      it 'returns array of CurrencyPair objects' do
        pairs = described_class.available_pairs
        expect(pairs).to all(be_a(CurrencyPair))
      end

      it 'generates pairs from supported currencies' do
        pairs = described_class.available_pairs
        expect(pairs).not_to be_empty
      end
    end

    describe 'inheritance' do
      it 'inherits from RateSource' do
        expect(described_class.superclass).to eq(RateSource)
      end
    end
  end
end
