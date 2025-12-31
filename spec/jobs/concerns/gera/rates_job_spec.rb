# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe RatesJob do
    # Create a test job class that includes RatesJob
    let(:test_job_class) do
      Class.new(ApplicationJob) do
        include Gera::RatesJob

        attr_accessor :test_rate_source, :test_rates

        def rate_source
          test_rate_source
        end

        def load_rates
          test_rates
        end

        def rate_keys
          { buy: 'buy_price', sell: 'sell_price' }
        end
      end
    end

    let(:job) { test_job_class.new }
    let!(:rate_source) { create(:rate_source_exmo) }

    before do
      job.test_rate_source = rate_source
    end

    describe '#perform' do
      context 'with valid rates' do
        before do
          job.test_rates = {
            'BTC/USD' => { 'buy_price' => 50000.0, 'sell_price' => 50100.0 },
            'ETH/USD' => { 'buy_price' => 3000.0, 'sell_price' => 3010.0 }
          }
        end

        it 'creates a rate source snapshot' do
          expect { job.perform }.to change(ExternalRateSnapshot, :count).by(1)
        end

        it 'returns snapshot id' do
          result = job.perform
          expect(result).to be_a(Integer)
        end

        it 'enqueues ExternalRatesBatchJob' do
          expect(ExternalRatesBatchJob).to receive(:perform_later)
            .with(kind_of(Integer), rate_source.id, kind_of(Hash))
          job.perform
        end
      end

      context 'with empty rates' do
        before do
          job.test_rates = {}
        end

        it 'creates a snapshot even with empty rates' do
          expect { job.perform }.to change(ExternalRateSnapshot, :count).by(1)
        end
      end

      context 'with array-based rate data' do
        let(:array_job_class) do
          Class.new(ApplicationJob) do
            include Gera::RatesJob

            attr_accessor :test_rate_source, :test_rates

            def rate_source
              test_rate_source
            end

            def load_rates
              test_rates
            end

            def rate_keys
              { buy: 7, sell: 7 }
            end
          end
        end

        let(:array_job) { array_job_class.new }

        before do
          array_job.test_rate_source = rate_source
          array_job.test_rates = {
            'BTC/USD' => [nil, nil, nil, nil, nil, nil, nil, 50000.0]
          }
        end

        it 'handles array-based rate data' do
          expect { array_job.perform }.to change(ExternalRateSnapshot, :count).by(1)
        end
      end
    end

    describe 'Error constant' do
      it 'defines Error class' do
        expect(described_class::Error).to be < StandardError
      end
    end
  end
end
