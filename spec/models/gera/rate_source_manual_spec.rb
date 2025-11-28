# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceManual do
    describe '.supported_currencies' do
      it 'returns all currencies' do
        expect(described_class.supported_currencies).to eq(Money::Currency.all)
      end
    end

    describe '.available_pairs' do
      it 'returns all currency pairs' do
        expect(described_class.available_pairs).to eq(CurrencyPair.all)
      end
    end

    describe 'inheritance' do
      it 'inherits from RateSource' do
        expect(described_class.superclass).to eq(RateSource)
      end
    end
  end
end
