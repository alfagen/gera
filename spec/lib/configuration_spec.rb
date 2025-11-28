# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gera::Configuration do
  describe '.configure' do
    it 'yields self to block' do
      expect { |b| Gera.configure(&b) }.to yield_with_args(Gera)
    end
  end

  describe '.default_cross_currency' do
    it 'returns Money::Currency object' do
      expect(Gera.default_cross_currency).to be_a(Money::Currency)
    end

    it 'defaults to USD' do
      expect(Gera.default_cross_currency.iso_code).to eq('USD')
    end
  end

  describe '.cross_pairs' do
    it 'returns hash with Money::Currency keys and values' do
      result = Gera.cross_pairs
      expect(result).to be_a(Hash)
      result.each do |key, value|
        expect(key).to be_a(Money::Currency)
        expect(value).to be_a(Money::Currency)
      end
    end
  end

  describe '.payment_system_decorator' do
    it 'responds to payment_system_decorator' do
      expect(Gera).to respond_to(:payment_system_decorator)
    end
  end
end
