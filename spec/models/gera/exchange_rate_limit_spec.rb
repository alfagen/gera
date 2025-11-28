# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe ExchangeRateLimit do
    # Note: This spec tests the model's interface.
    # The table gera_exchange_rate_limits may not exist in test database.

    describe 'model interface' do
      it 'inherits from ApplicationRecord' do
        expect(ExchangeRateLimit.superclass).to eq(ApplicationRecord)
      end

      it 'is defined as a class' do
        expect(ExchangeRateLimit).to be_a(Class)
      end

      it 'has exchange_rate association defined' do
        expect(ExchangeRateLimit.reflect_on_association(:exchange_rate)).to be_present
      end
    end
  end
end
