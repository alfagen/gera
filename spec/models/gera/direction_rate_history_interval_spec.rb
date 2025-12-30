# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe DirectionRateHistoryInterval do
    describe 'HistoryIntervalConcern' do
      it 'includes HistoryIntervalConcern module' do
        expect(DirectionRateHistoryInterval.include?(HistoryIntervalConcern)).to be true
      end
    end

    describe 'model interface' do
      it 'inherits from ApplicationRecord' do
        expect(DirectionRateHistoryInterval.superclass).to eq(ApplicationRecord)
      end

      it 'responds to interval_from and interval_to' do
        interval = DirectionRateHistoryInterval.new
        expect(interval).to respond_to(:interval_from)
        expect(interval).to respond_to(:interval_to)
      end

      it 'responds to payment system id attributes' do
        interval = DirectionRateHistoryInterval.new
        # Note: associations are commented out in the model,
        # so we test the id columns directly
        expect(interval).to respond_to(:payment_system_from_id)
        expect(interval).to respond_to(:payment_system_to_id)
      end

      it 'responds to rate aggregation attributes' do
        interval = DirectionRateHistoryInterval.new
        expect(interval).to respond_to(:min_rate)
        expect(interval).to respond_to(:max_rate)
        expect(interval).to respond_to(:min_comission)
        expect(interval).to respond_to(:max_comission)
      end
    end

    describe '.create_by_interval!' do
      it 'responds to create_by_interval! class method' do
        expect(DirectionRateHistoryInterval).to respond_to(:create_by_interval!)
      end
    end
  end
end
