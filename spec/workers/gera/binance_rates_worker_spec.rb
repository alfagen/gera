# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe BinanceRatesWorker do
    before do
      create :rate_source_binance
      create :rate_source_cbr_avg
      create :rate_source_cbr
      create :rate_source_manual
    end

    it do
      expect(CurrencyRate.count).to be_zero
      threads = []
      3.times do |i|
        threads << Thread.new do
          puts "START THREAD #{i + 1}"
          sleep 0.013 * (i + 1)
          VCR.use_cassette "binance#{i + 1}" do
            expect(BinanceRatesWorker.new.perform).to be_truthy
          end
        end
      end
      threads.each(&:join)
      expect(CurrencyRate.count).to eq 175
    end
  end
end
