# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateHistoryInterval do
    describe 'HistoryIntervalConcern' do
      it 'includes HistoryIntervalConcern module' do
        expect(CurrencyRateHistoryInterval.include?(HistoryIntervalConcern)).to be true
      end
    end

    describe 'model interface' do
      it 'inherits from ApplicationRecord' do
        expect(CurrencyRateHistoryInterval.superclass).to eq(ApplicationRecord)
      end

      it 'responds to interval_from and interval_to' do
        interval = CurrencyRateHistoryInterval.new
        expect(interval).to respond_to(:interval_from)
        expect(interval).to respond_to(:interval_to)
      end

      it 'responds to currency id attributes' do
        interval = CurrencyRateHistoryInterval.new
        expect(interval).to respond_to(:cur_from_id)
        expect(interval).to respond_to(:cur_to_id)
      end

      it 'responds to rate aggregation attributes' do
        interval = CurrencyRateHistoryInterval.new
        expect(interval).to respond_to(:min_rate)
        expect(interval).to respond_to(:max_rate)
      end
    end

    describe '.create_by_interval!' do
      it 'responds to create_by_interval! class method' do
        expect(CurrencyRateHistoryInterval).to respond_to(:create_by_interval!)
      end
    end
  end
end
