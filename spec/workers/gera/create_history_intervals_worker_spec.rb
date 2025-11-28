# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CreateHistoryIntervalsWorker do
    describe 'constants' do
      it 'defines MAXIMAL_DATE as 30 minutes' do
        expect(described_class::MAXIMAL_DATE).to eq(30.minutes)
      end

      it 'defines MINIMAL_DATE' do
        expect(described_class::MINIMAL_DATE).to be_a(Time)
      end
    end

    describe '#perform' do
      context 'when tables exist' do
        it 'calls save_direction_rate_history_intervals' do
          expect(DirectionRateHistoryInterval).to receive(:table_exists?).and_return(true)
          expect(CurrencyRateHistoryInterval).to receive(:table_exists?).and_return(true)

          worker = described_class.new
          # Stub the actual save methods to avoid complex setup
          allow(worker).to receive(:save_direction_rate_history_intervals)
          allow(worker).to receive(:save_currency_rate_history_intervals)

          worker.perform

          expect(worker).to have_received(:save_direction_rate_history_intervals)
          expect(worker).to have_received(:save_currency_rate_history_intervals)
        end
      end

      context 'when tables do not exist' do
        it 'skips saving intervals' do
          allow(DirectionRateHistoryInterval).to receive(:table_exists?).and_return(false)
          allow(CurrencyRateHistoryInterval).to receive(:table_exists?).and_return(false)

          expect(DirectionRateHistoryInterval).not_to receive(:create_multiple_intervals_from!)
          expect(CurrencyRateHistoryInterval).not_to receive(:create_multiple_intervals_from!)

          subject.perform
        end
      end
    end

    describe 'sidekiq_options' do
      it 'uses until_executed lock' do
        expect(described_class.sidekiq_options['lock']).to eq(:until_executed)
      end
    end
  end
end
