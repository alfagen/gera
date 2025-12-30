# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gera::Numeric do
  describe '#to_rate' do
    it 'converts number to RateFromMultiplicator' do
      result = 100.to_rate
      expect(result).to be_a(Gera::RateFromMultiplicator)
    end

    it 'preserves the value' do
      result = 100.to_rate
      expect(result.to_f).to eq(100.0)
    end
  end

  describe '#percent_of' do
    it 'calculates percentage of a value' do
      result = 10.percent_of(100)
      expect(result).to eq(10)
    end

    it 'handles decimal percentages' do
      result = 2.5.percent_of(100)
      expect(result).to eq(2.5)
    end
  end

  describe '#as_percentage_of' do
    it 'calculates what percentage one number is of another' do
      result = 5.as_percentage_of(10)
      # Returns percentage as decimal (0.5 = 50%)
      expect(result.to_f).to eq(0.5)
    end

    it 'handles decimal values' do
      result = 25.as_percentage_of(100)
      # Returns percentage as decimal (0.25 = 25%)
      expect(result.to_f).to eq(0.25)
    end
  end

  describe 'Numeric extension' do
    it 'extends ::Numeric class' do
      expect(::Numeric.include?(Gera::Numeric)).to be true
    end

    it 'works with Integer' do
      expect(100).to respond_to(:to_rate)
      expect(100).to respond_to(:percent_of)
      expect(100).to respond_to(:as_percentage_of)
    end

    it 'works with Float' do
      expect(10.5).to respond_to(:to_rate)
      expect(10.5).to respond_to(:percent_of)
      expect(10.5).to respond_to(:as_percentage_of)
    end
  end
end
