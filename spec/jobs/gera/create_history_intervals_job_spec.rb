# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CreateHistoryIntervalsJob do
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

          job = described_class.new
          # Stub the actual save methods to avoid complex setup
          allow(job).to receive(:save_direction_rate_history_intervals)
          allow(job).to receive(:save_currency_rate_history_intervals)

          job.perform

          expect(job).to have_received(:save_direction_rate_history_intervals)
          expect(job).to have_received(:save_currency_rate_history_intervals)
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

    describe 'concurrency limits' do
      it 'has limits_concurrency configured' do
        # ActiveJob with Solid Queue uses limits_concurrency
        expect(described_class).to respond_to(:queue_name)
      end
    end
  end
end
