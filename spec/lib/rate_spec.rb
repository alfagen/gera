# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gera::Rate do
  describe 'attributes' do
    let(:rate) { described_class.new(in_amount: 1, out_amount: 100) }

    it 'has in_amount attribute' do
      expect(rate.in_amount).to eq(1)
    end

    it 'has out_amount attribute' do
      expect(rate.out_amount).to eq(100)
    end
  end

  describe '#to_d' do
    it 'returns ratio of out_amount to in_amount as BigDecimal' do
      rate = described_class.new(in_amount: 1, out_amount: 100)
      expect(rate.to_d).to eq(100.to_d)
    end

    it 'handles decimal values' do
      rate = described_class.new(in_amount: 2, out_amount: 5)
      expect(rate.to_d).to eq(2.5.to_d)
    end
  end

  describe '#to_f' do
    it 'returns ratio as Float' do
      rate = described_class.new(in_amount: 1, out_amount: 100)
      expect(rate.to_f).to eq(100.0)
    end
  end

  describe '#reverse' do
    it 'swaps in_amount and out_amount' do
      rate = described_class.new(in_amount: 1, out_amount: 100)
      reversed = rate.reverse

      expect(reversed.in_amount).to eq(100)
      expect(reversed.out_amount).to eq(1)
    end

    it 'returns frozen object' do
      rate = described_class.new(in_amount: 1, out_amount: 100)
      expect(rate.reverse).to be_frozen
    end
  end

  describe 'inheritance' do
    it 'inherits from RateFromMultiplicator' do
      expect(described_class.superclass).to eq(Gera::RateFromMultiplicator)
    end
  end
end
