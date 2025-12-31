# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'ostruct'

module Gera
  RSpec.describe CbrRatesJob do
    before do
      create :rate_source_exmo
      create :rate_source_cbr_avg
      create :rate_source_cbr

      # Mock the external HTTP request to avoid VCR/network issues
      mock_cbr_response
    end

    let(:today) { Date.parse '13/03/2018' }

    it do
      expect(ExternalRate.count).to be_zero

      # На teamcity почему-то дата возвращается как 2018-03-12
      allow(Date).to receive(:today).and_return today
      Timecop.freeze(today) do
        expect(CbrRatesJob.new.perform).to be_truthy
      end

      expect(ExternalRate.count).to be > 0
    end

    private

    def mock_cbr_response
      # Mock the entire fetch_rates method to return XML root node
      today = Date.parse('13/03/2018')
      job = CbrRatesJob.new

      # Create mock XML root node
      root = double('XML root')

      # Mock fetch_rates to return XML root for each date
      allow(job).to receive(:fetch_rates) do |date|
        next if date != today  # Only return data for the target date
        root
      end

      # Mock get_rate to return rate data
      allow(job).to receive(:get_rate) do |xml_root, currency_id|
        rate_data = {
          'R01235' => 56.7594,  # USD
          'R01335' => 1.67351,  # KZT (100 -> 16.7351)
          'R01239' => 70.1974,  # EUR
          'R01720' => 2.03578,  # UAH (10 -> 20.3578)
          'R01717' => 0.0068372, # UZS (1000 -> 6.8372)
          'R01020A' => 33.4799,  # AZN
          'R01090B' => 28.6515,  # BYN
          'R01700J' => 14.0985,  # TRY
          'R01675' => 1.79972,  # THB (10 -> 17.9972)
          'R01280' => 0.00041809 # IDR (10000 -> 4.1809)
        }

        rate = rate_data[currency_id]
        OpenStruct.new(original_rate: rate, nominal: 1.0) if rate
      end

      allow(CbrRatesJob).to receive(:new).and_return(job)
    end
  end
end
