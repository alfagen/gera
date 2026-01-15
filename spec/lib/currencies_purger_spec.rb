# frozen_string_literal: true

require 'spec_helper'
require 'gera/currencies_purger'

RSpec.describe Gera::CurrenciesPurger do
  describe '.purge_all' do
    it 'raises error when env does not match Rails.env' do
      expect { described_class.purge_all('wrong_env') }.to raise_error(RuntimeError)
    end

    it 'responds to purge_all method' do
      expect(described_class).to respond_to(:purge_all)
    end

    # Note: Full integration testing of purge_all would require
    # complex database setup and is risky to run in test environment.
    # The method is designed for production/staging maintenance.
  end
end
