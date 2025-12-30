# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceGarantexio do
    describe '.supported_currencies' do
      it 'returns array of Money::Currency objects' do
        currencies = described_class.supported_currencies
        expect(currencies).to all(be_a(Money::Currency))
      end

      it 'includes USDT, BTC, and RUB' do
        iso_codes = described_class.supported_currencies.map(&:iso_code)
        expect(iso_codes).to include('USDT', 'BTC', 'RUB')
      end
    end

    describe 'inheritance' do
      it 'inherits from RateSource' do
        expect(described_class.superclass).to eq(RateSource)
      end
    end
  end
end
