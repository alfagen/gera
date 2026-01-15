# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe PaymentSystemsRepository do
    subject(:repository) { described_class.new }

    let!(:payment_system1) { create(:gera_payment_system, income_enabled: true, outcome_enabled: true, is_available: true) }
    let!(:payment_system2) { create(:gera_payment_system, income_enabled: true, outcome_enabled: true, is_available: true) }
    let!(:unavailable_ps) { create(:gera_payment_system, income_enabled: false, outcome_enabled: false, is_available: false) }

    describe '#find_by_id' do
      it 'returns payment system by id' do
        expect(repository.find_by_id(payment_system1.id)).to eq(payment_system1)
      end

      it 'returns nil for non-existent id' do
        expect(repository.find_by_id(-1)).to be_nil
      end
    end

    describe '#available' do
      it 'returns only available payment systems' do
        available = repository.available
        expect(available).to include(payment_system1)
        expect(available).to include(payment_system2)
        expect(available).not_to include(unavailable_ps)
      end

      it 'memoizes the result' do
        expect(repository.available).to eq(repository.available)
      end
    end

    describe '#all' do
      it 'returns all payment systems' do
        all = repository.all
        expect(all).to include(payment_system1)
        expect(all).to include(payment_system2)
        expect(all).to include(unavailable_ps)
      end
    end
  end
end
