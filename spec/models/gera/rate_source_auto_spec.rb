# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceAuto do
    describe 'inheritance' do
      it 'inherits from RateSource' do
        expect(described_class.superclass).to eq(RateSource)
      end
    end

    describe '#build_currency_rate' do
      subject { described_class.new }

      context 'when pair has same currencies' do
        let(:pair) { CurrencyPair.new('USD/USD') }

        it 'returns CurrencyRate with rate_value 1' do
          result = subject.build_currency_rate(pair)
          expect(result.rate_value).to eq(1)
        end

        it 'sets mode to same' do
          result = subject.build_currency_rate(pair)
          expect(result.mode).to eq('same')
        end
      end
    end
  end
end
