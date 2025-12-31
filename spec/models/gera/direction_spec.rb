# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe Direction do
    let(:ps_from) { create(:gera_payment_system) }
    let(:ps_to) { create(:gera_payment_system) }
    subject { described_class.new(ps_from: ps_from, ps_to: ps_to) }

    describe 'Virtus model' do
      it 'includes Virtus.model' do
        expect(described_class.include?(Virtus::Model::Core)).to be true
      end
    end

    describe 'attributes' do
      it 'has ps_from attribute' do
        expect(subject.ps_from).to eq(ps_from)
      end

      it 'has ps_to attribute' do
        expect(subject.ps_to).to eq(ps_to)
      end
    end

    describe 'attribute aliases' do
      it 'aliases payment_system_from to ps_from' do
        expect(subject.payment_system_from).to eq(subject.ps_from)
      end

      it 'aliases payment_system_to to ps_to' do
        expect(subject.payment_system_to).to eq(subject.ps_to)
      end

      it 'aliases income_payment_system to ps_from' do
        expect(subject.income_payment_system).to eq(subject.ps_from)
      end

      it 'aliases outcome_payment_system to ps_to' do
        expect(subject.outcome_payment_system).to eq(subject.ps_to)
      end
    end

    describe '#currency_from' do
      it 'returns currency from payment_system_from' do
        expect(subject.currency_from).to eq(ps_from.currency)
      end
    end

    describe '#currency_to' do
      it 'returns currency from payment_system_to' do
        expect(subject.currency_to).to eq(ps_to.currency)
      end
    end

    describe '#ps_to_id' do
      it 'delegates to ps_to' do
        expect(subject.ps_to_id).to eq(ps_to.id)
      end
    end

    describe '#ps_from_id' do
      it 'delegates to ps_from' do
        expect(subject.ps_from_id).to eq(ps_from.id)
      end
    end

    describe '#to_s' do
      it 'returns formatted string with payment system ids' do
        expect(subject.to_s).to eq("direction:#{ps_from.id}-#{ps_to.id}")
      end

      context 'when ps_from is nil' do
        subject { described_class.new(ps_from: nil, ps_to: ps_to) }

        it 'uses ??? placeholder' do
          expect(subject.to_s).to include('???')
        end
      end
    end

    describe '#inspect' do
      it 'returns same as to_s' do
        expect(subject.inspect).to eq(subject.to_s)
      end
    end
  end
end
