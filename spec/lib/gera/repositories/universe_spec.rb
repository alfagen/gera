# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe Universe do
    describe '.instance' do
      it 'returns a Universe instance' do
        expect(described_class.instance).to be_a(Universe)
      end

      it 'returns the same instance within the same request' do
        expect(described_class.instance).to eq(described_class.instance)
      end
    end

    describe '.clear!' do
      it 'clears the cached repositories' do
        universe = described_class.instance
        universe.payment_systems # initialize cache

        described_class.clear!

        # After clear, a new repository should be created
        expect(universe.instance_variable_get(:@payment_systems)).to be_nil
      end
    end

    describe '#payment_systems' do
      it 'returns a PaymentSystemsRepository' do
        expect(described_class.instance.payment_systems).to be_a(PaymentSystemsRepository)
      end

      it 'memoizes the repository' do
        universe = described_class.instance
        expect(universe.payment_systems).to eq(universe.payment_systems)
      end
    end

    describe '#currency_rate_modes_repository' do
      it 'returns a CurrencyRateModesRepository' do
        expect(described_class.instance.currency_rate_modes_repository).to be_a(CurrencyRateModesRepository)
      end
    end

    describe '#currency_rates_repository' do
      it 'returns a CurrencyRatesRepository' do
        expect(described_class.instance.currency_rates_repository).to be_a(CurrencyRatesRepository)
      end
    end

    describe '#direction_rates_repository' do
      it 'returns a DirectionRatesRepository' do
        expect(described_class.instance.direction_rates_repository).to be_a(DirectionRatesRepository)
      end
    end

    describe '#exchange_rates_repository' do
      it 'returns an ExchangeRatesRepository' do
        expect(described_class.instance.exchange_rates_repository).to be_a(ExchangeRatesRepository)
      end
    end
  end
end
