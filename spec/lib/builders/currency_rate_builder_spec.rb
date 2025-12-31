# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateBuilder do
    let(:currency_pair) { CurrencyPair.new('BTC/USD') }

    describe CurrencyRateBuilder::SuccessResult do
      let(:currency_rate) { instance_double(CurrencyRate) }
      let(:result) { described_class.new(currency_rate: currency_rate) }

      it 'returns true for success?' do
        expect(result.success?).to be true
      end

      it 'returns false for error?' do
        expect(result.error?).to be false
      end

      it 'returns currency_rate' do
        expect(result.currency_rate).to eq(currency_rate)
      end
    end

    describe CurrencyRateBuilder::ErrorResult do
      let(:error) { StandardError.new('test error') }
      let(:result) { described_class.new(error: error) }

      it 'returns false for success?' do
        expect(result.success?).to be false
      end

      it 'returns true for error?' do
        expect(result.error?).to be true
      end

      it 'returns nil for currency_rate' do
        expect(result.currency_rate).to be_nil
      end

      it 'returns error' do
        expect(result.error).to eq(error)
      end
    end

    describe '#build_currency_rate' do
      subject { described_class.new(currency_pair: currency_pair) }

      it 'raises error because build is not implemented' do
        result = subject.build_currency_rate
        expect(result).to be_a(CurrencyRateBuilder::ErrorResult)
        expect(result.error.message).to eq('not implemented')
      end
    end
  end
end
