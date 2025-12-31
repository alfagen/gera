# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe DirectionRateHistoryIntervalFilter do
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
      let!(:payment_system) { create(:gera_payment_system) }
      subject { described_class.new }

      it 'has payment_system_from_id attribute' do
        expect(subject).to respond_to(:payment_system_from_id)
      end

      it 'has payment_system_to_id attribute' do
        expect(subject).to respond_to(:payment_system_to_id)
      end

      it 'has value_type attribute with default rate' do
        expect(subject.value_type).to eq('rate')
      end
    end

    describe '#payment_system_from' do
      let(:payment_system) { create(:gera_payment_system) }
      subject { described_class.new(payment_system_from_id: payment_system.id) }

      it 'returns PaymentSystem object' do
        expect(subject.payment_system_from).to eq(payment_system)
      end
    end

    describe '#payment_system_to' do
      let(:payment_system) { create(:gera_payment_system) }
      subject { described_class.new(payment_system_to_id: payment_system.id) }

      it 'returns PaymentSystem object' do
        expect(subject.payment_system_to).to eq(payment_system)
      end
    end

    describe '#to_param' do
      let(:ps_from) { create(:gera_payment_system) }
      let(:ps_to) { create(:gera_payment_system) }
      subject { described_class.new(payment_system_from_id: ps_from.id, payment_system_to_id: ps_to.id) }

      it 'returns hash representation' do
        expect(subject.to_param).to be_a(Hash)
      end
    end

    describe '#persisted?' do
      let!(:payment_system) { create(:gera_payment_system) }
      subject { described_class.new }

      it 'returns false' do
        expect(subject.persisted?).to be false
      end
    end
  end
end
