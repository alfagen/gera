# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceFfFixed do
    describe '.supported_currencies' do
      it 'returns array of Money::Currency objects' do
        currencies = described_class.supported_currencies
        expect(currencies).to all(be_a(Money::Currency))
      end

      it 'includes major crypto currencies' do
        iso_codes = described_class.supported_currencies.map(&:iso_code)
        expect(iso_codes).to include('BTC', 'ETH', 'LTC', 'USDT')
      end

      it 'includes TON' do
        iso_codes = described_class.supported_currencies.map(&:iso_code)
        expect(iso_codes).to include('TON')
      end
    end

    describe 'inheritance' do
      it 'inherits from RateSource' do
        expect(described_class.superclass).to eq(RateSource)
      end
    end
  end
end
