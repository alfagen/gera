# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceCbr do
    describe '.supported_currencies' do
      it 'returns array of Money::Currency objects' do
        currencies = described_class.supported_currencies
        expect(currencies).to all(be_a(Money::Currency))
      end

      it 'includes RUB' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('RUB')
      end

      it 'includes KZT' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('KZT')
      end

      it 'includes USD' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('USD')
      end

      it 'includes EUR' do
        expect(described_class.supported_currencies.map(&:iso_code)).to include('EUR')
      end
    end

    describe '.available_pairs' do
      it 'returns predefined currency pairs' do
        pairs = described_class.available_pairs
        expect(pairs).to all(be_a(CurrencyPair))
      end

      it 'includes USD/RUB pair' do
        pair_strings = described_class.available_pairs.map(&:to_s)
        expect(pair_strings).to include('USD/RUB')
      end

      it 'includes EUR/RUB pair' do
        pair_strings = described_class.available_pairs.map(&:to_s)
        expect(pair_strings).to include('EUR/RUB')
      end
    end

    describe 'inheritance' do
      it 'inherits from RateSource' do
        expect(described_class.superclass).to eq(RateSource)
      end
    end
  end
end
