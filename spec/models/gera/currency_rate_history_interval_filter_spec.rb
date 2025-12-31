# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateHistoryIntervalFilter do
    describe 'included modules' do
      it 'includes Virtus.model' do
        expect(described_class.include?(Virtus::Model::Core)).to be true
      end

      it 'includes ActiveModel::Conversion' do
        expect(described_class.include?(ActiveModel::Conversion)).to be true
      end

      it 'extends ActiveModel::Naming' do
        expect(described_class).to respond_to(:model_name)
      end

      it 'includes ActiveModel::Validations' do
        expect(described_class.include?(ActiveModel::Validations)).to be true
      end
    end

    describe 'attributes' do
      subject { described_class.new }

      it 'has cur_from attribute with default' do
        expect(subject.cur_from).to be_present
      end

      it 'has cur_to attribute with default' do
        expect(subject.cur_to).to be_present
      end

      it 'has value_type attribute with default rate' do
        expect(subject.value_type).to eq('rate')
      end
    end

    describe '#currency_from' do
      subject { described_class.new(cur_from: 'BTC') }

      it 'returns Money::Currency object' do
        expect(subject.currency_from).to be_a(Money::Currency)
        expect(subject.currency_from.iso_code).to eq('BTC')
      end
    end

    describe '#currency_to' do
      subject { described_class.new(cur_to: 'USD') }

      it 'returns Money::Currency object' do
        expect(subject.currency_to).to be_a(Money::Currency)
        expect(subject.currency_to.iso_code).to eq('USD')
      end
    end

    describe '#to_param' do
      subject { described_class.new(cur_from: 'BTC', cur_to: 'USD') }

      it 'returns hash representation' do
        expect(subject.to_param).to be_a(Hash)
        expect(subject.to_param[:cur_from]).to eq('BTC')
        expect(subject.to_param[:cur_to]).to eq('USD')
      end
    end

    describe '#persisted?' do
      subject { described_class.new }

      it 'returns false' do
        expect(subject.persisted?).to be false
      end
    end
  end
end
