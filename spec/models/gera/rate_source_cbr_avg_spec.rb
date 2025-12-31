# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RateSourceCbrAvg do
    describe 'inheritance' do
      it 'inherits from RateSourceCbr' do
        expect(described_class.superclass).to eq(RateSourceCbr)
      end
    end

    describe '.supported_currencies' do
      it 'inherits supported currencies from RateSourceCbr' do
        expect(described_class.supported_currencies).to eq(RateSourceCbr.supported_currencies)
      end
    end

    describe '.available_pairs' do
      it 'inherits available pairs from RateSourceCbr' do
        expect(described_class.available_pairs).to eq(RateSourceCbr.available_pairs)
      end
    end
  end
end
